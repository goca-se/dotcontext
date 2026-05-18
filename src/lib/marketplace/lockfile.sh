# ── lib/marketplace/lockfile.sh ───────────────────────────────────────────────
#
# Read/write per-scope lockfile.
#
# Schemas: see ADR-016.
#   local:  <project>/.context/.dotcontext-state.json
#   global: ~/.dotcontext/state.json
#
# Public API:
#   mp_lock_path <scope>           # echoes path
#   mp_lock_init <scope>           # creates empty lockfile if missing
#   mp_lock_has <scope> <id>       # exit 0 if installed, 1 otherwise
#   mp_lock_get_field <scope> <id> <field>
#   mp_lock_add <scope> <id> <version> <files-newline-list> [extra-jq-merge]
#   mp_lock_remove <scope> <id>
#   mp_lock_list_ids <scope>
#   mp_lock_list_with_dependents <scope> <id>   # returns ids depending on id

mp_lock_path() {
  local scope="$1"
  case "$scope" in
    local)
      if [ -d "${PWD}/.context" ]; then
        echo "${PWD}/.context/.dotcontext-state.json"
      else
        # Walk up to find a .context dir (project root).
        local d="$PWD"
        while [ "$d" != "/" ] && [ -n "$d" ]; do
          if [ -d "$d/.context" ]; then
            echo "$d/.context/.dotcontext-state.json"
            return 0
          fi
          d="$(dirname "$d")"
        done
        echo "${PWD}/.context/.dotcontext-state.json"
      fi
      ;;
    global|machine)
      mkdir -p "$HOME/.dotcontext" 2>/dev/null
      echo "$HOME/.dotcontext/state.json"
      ;;
    *)
      printf 'mp_lock_path: unknown scope %s\n' "$scope" >&2
      return 1
      ;;
  esac
}

mp_lock_init() {
  local scope="$1"
  local path
  path="$(mp_lock_path "$scope")" || return 1
  if [ ! -f "$path" ]; then
    mkdir -p "$(dirname "$path")"
    printf '{ "$schema_version": "1.0", "items": [] }\n' > "$path"
  fi
}

# Atomic write helper.
mp_lock_write() {
  local path="$1"
  local content="$2"
  local tmp="${path}.tmp.$$"
  printf '%s\n' "$content" > "$tmp"
  mv "$tmp" "$path"
}

mp_lock_has() {
  local scope="$1" id="$2"
  local path
  path="$(mp_lock_path "$scope")" || return 1
  [ -f "$path" ] || return 1
  # Filter by both id AND scope. Global + machine share the same lockfile
  # file (~/.dotcontext/state.json), so we must distinguish by the scope
  # field on each entry; otherwise a global-only item appears as also
  # machine-installed (and vice versa).
  jq -e --arg id "$id" --arg s "$scope" \
    '.items[] | select(.id == $id and .scope == $s)' "$path" >/dev/null 2>&1
}

mp_lock_get_field() {
  local scope="$1" id="$2" field="$3"
  local path
  path="$(mp_lock_path "$scope")" || return 1
  [ -f "$path" ] || return 1
  jq -r --arg id "$id" --arg s "$scope" --arg f "$field" \
    '.items[] | select(.id == $id and .scope == $s) | .[$f] // empty' "$path"
}

mp_lock_list_ids() {
  local scope="$1"
  local path
  path="$(mp_lock_path "$scope")" || return 1
  [ -f "$path" ] || return 0
  jq -r --arg s "$scope" '.items[] | select(.scope == $s) | .id' "$path"
}

# mp_lock_add: idempotent — if id already present, replace entry.
mp_lock_add() {
  local scope="$1" id="$2" version="$3" files="$4"
  local path now files_json
  path="$(mp_lock_path "$scope")" || return 1
  mp_lock_init "$scope" || return 1
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # files arg is newline-separated.
  if [ -n "$files" ]; then
    files_json="$(printf '%s\n' "$files" | jq -R . | jq -s .)"
  else
    files_json="[]"
  fi

  local content
  content="$(jq --arg id "$id" --arg v "$version" --arg s "$scope" --arg t "$now" \
    --argjson files "$files_json" \
    '
      .items |= (map(select(.id != $id))) |
      .items += [{ id: $id, version: $v, scope: $s, installed_at: $t, files: $files }]
    ' "$path")" || return 1
  mp_lock_write "$path" "$content"
}

# Variant for items with settings_keys (mcp/hook).
mp_lock_add_with_keys() {
  local scope="$1" id="$2" version="$3" keys_csv="$4"
  local path now keys_json
  path="$(mp_lock_path "$scope")" || return 1
  mp_lock_init "$scope" || return 1
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [ -n "$keys_csv" ]; then
    keys_json="$(printf '%s' "$keys_csv" | tr ',' '\n' | jq -R . | jq -s .)"
  else
    keys_json="[]"
  fi

  local content
  content="$(jq --arg id "$id" --arg v "$version" --arg s "$scope" --arg t "$now" \
    --argjson keys "$keys_json" \
    '
      .items |= (map(select(.id != $id))) |
      .items += [{ id: $id, version: $v, scope: $s, installed_at: $t, settings_keys: $keys }]
    ' "$path")" || return 1
  mp_lock_write "$path" "$content"
}

# Variant for external-cli.
mp_lock_add_cli() {
  local id="$1" version="$2" pm="$3"
  local path now
  path="$(mp_lock_path machine)" || return 1
  mp_lock_init machine || return 1
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local content
  content="$(jq --arg id "$id" --arg v "$version" --arg pm "$pm" --arg t "$now" \
    '
      .items |= (map(select(.id != $id))) |
      .items += [{ id: $id, version: $v, scope: "machine", installed_at: $t, package_manager_used: $pm }]
    ' "$path")" || return 1
  mp_lock_write "$path" "$content"
}

mp_lock_remove() {
  local scope="$1" id="$2"
  local path content
  path="$(mp_lock_path "$scope")" || return 1
  [ -f "$path" ] || return 0
  content="$(jq --arg id "$id" '.items |= map(select(.id != $id))' "$path")" || return 1
  mp_lock_write "$path" "$content"
}

# List ids whose depends_on includes <id> in the given scope.
mp_lock_list_dependents() {
  local scope="$1" id="$2"
  # Note: depends_on lives in the manifest, not the lockfile. Caller should
  # cross-reference manifest using mp_manifest_depends_on against
  # mp_lock_list_ids. Implemented here for convenience.
  local installed dep
  installed="$(mp_lock_list_ids "$scope")"
  while IFS= read -r dep; do
    [ -z "$dep" ] && continue
    if mp_manifest_depends_on "$dep" 2>/dev/null | grep -qx "$id"; then
      echo "$dep"
    fi
  done <<EOF
$installed
EOF
}
