# ── lib/install/command.sh ────────────────────────────────────────────────────
#
# Install/remove handler for type=command-bundle (and skill, hook, script —
# they share the file-copy mechanic; specialised handlers wrap this).
#
# Public API:
#   mp_install_files <id> <scope>     # copies all files in the bundle
#   mp_remove_files  <id> <scope>     # deletes files recorded in the lockfile

# Internal: download a single file from GitHub raw content, or copy from local
# repo if running in dev mode (DOTCONTEXT_REPO_ROOT set).
_mp_fetch_file() {
  local src="$1" dest="$2"
  local dir
  dir="$(dirname "$dest")"
  mkdir -p "$dir" || return 1

  if [ -n "${DOTCONTEXT_REPO_ROOT:-}" ] && [ -f "$DOTCONTEXT_REPO_ROOT/$src" ]; then
    cp "$DOTCONTEXT_REPO_ROOT/$src" "$dest" || return 1
    return 0
  fi

  local url="https://raw.githubusercontent.com/goca-se/dotcontext/main/$src"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest" 2>/dev/null || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url" 2>/dev/null || return 1
  else
    printf 'no curl or wget available\n' >&2
    return 1
  fi
}

mp_install_files() {
  local id="$1" scope="$2"
  local installed=""
  local pair src dest abs_dest

  while IFS=$'\t' read -r src dest; do
    [ -z "$src" ] && continue
    abs_dest="$(mp_scope_resolve "$scope" "$dest")" || {
      _mp_rollback "$installed"
      return 1
    }
    if ! _mp_fetch_file "$src" "$abs_dest"; then
      printf 'mp_install: fetch failed for %s\n' "$src" >&2
      _mp_rollback "$installed"
      return 1
    fi
    installed="${installed}${abs_dest}"$'\n'
  done <<EOF
$(mp_bundle_resolve_files "$id")
EOF

  # Record only the *direct* files (relative to scope root) in lockfile so
  # remove can delete cleanly.
  local rel_list=""
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    local root
    root="$(mp_scope_root "$scope")"
    rel_list="${rel_list}${f#${root}/}"$'\n'
  done <<EOF
$installed
EOF
  rel_list="${rel_list%$'\n'}"

  local version
  version="$(mp_manifest_field "$id" version)"
  mp_lock_add "$scope" "$id" "$version" "$rel_list"
}

_mp_rollback() {
  local files="$1" f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    rm -f "$f" 2>/dev/null
  done <<EOF
$files
EOF
}

mp_remove_files() {
  local id="$1" scope="$2"
  local path root
  path="$(mp_lock_path "$scope")" || return 1
  [ -f "$path" ] || return 0
  root="$(mp_scope_root "$scope")"

  local files
  files="$(jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .files // [] | .[]' "$path")"

  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    rm -f "$root/$f" 2>/dev/null || true
    # Try to clean up empty parent dirs (e.g., .claude/agents/code-review/).
    local d
    d="$(dirname "$root/$f")"
    while [ "$d" != "$root" ] && [ "$d" != "/" ] && [ -d "$d" ]; do
      rmdir "$d" 2>/dev/null || break
      d="$(dirname "$d")"
    done
  done <<EOF
$files
EOF

  mp_lock_remove "$scope" "$id"
}
