# ── lib/marketplace/manifest.sh ───────────────────────────────────────────────
#
# Loads, queries, and caches the marketplace manifest.
#
# Runtime requires jq. We chose this over a pure-bash JSON parser to keep
# install handlers small. validate-manifest (build-time) works without jq.
#
# Public API:
#   mp_manifest_require_jq           # exits with helpful message if jq missing
#   mp_manifest_path                 # echoes path to embedded manifest
#   mp_manifest_load [path]          # caches contents of the manifest into MP_MANIFEST_JSON
#   mp_manifest_ids                  # echoes all item ids
#   mp_manifest_starter_pack_ids     # echoes starter pack ids
#   mp_manifest_field <id> <field>   # echoes a top-level field (.type, .name, etc.)
#   mp_manifest_files <id>           # echoes "src<TAB>dest" pairs, one per line
#   mp_manifest_depends_on <id>      # echoes dependency ids
#   mp_manifest_scopes <id>          # echoes scopes_supported
#   mp_manifest_default_scope <id>
#   mp_manifest_pm_for_os <id> <os-key>   # for external-cli; echoes JSON object for that OS

MP_MANIFEST_JSON=""
MP_MANIFEST_PATH=""

mp_manifest_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    printf 'dotcontext: jq is required for the marketplace TUI.\n' >&2
    printf 'Install jq:\n' >&2
    printf '  macOS:    brew install jq\n' >&2
    printf '  Debian:   sudo apt-get install jq\n' >&2
    printf '  Fedora:   sudo dnf install jq\n' >&2
    return 1
  fi
}

# Resolves the manifest path, fetching from the marketplace repo if needed.
# Resolution order (first hit wins):
#   1. $DOTCONTEXT_MANIFEST (explicit override — for tests or pinning a copy)
#   2. $DOTCONTEXT_MARKETPLACE_ROOT/manifest.json (local dev — pointing at a
#      clone of goca-se/dotcontext-marketplace)
#   3. $HOME/.dotcontext/cache/manifest.json (fetched copy, refreshable)
#   4. Network fetch from $MARKETPLACE_URL/manifest.json to (3), then use it
mp_manifest_path() {
  if [ -n "$MP_MANIFEST_PATH" ]; then
    echo "$MP_MANIFEST_PATH"; return 0
  fi

  # 1. Explicit override
  if [ -n "${DOTCONTEXT_MANIFEST:-}" ] && [ -f "${DOTCONTEXT_MANIFEST}" ]; then
    MP_MANIFEST_PATH="$DOTCONTEXT_MANIFEST"
    echo "$MP_MANIFEST_PATH"; return 0
  fi

  # 2. Local marketplace clone (dev)
  if [ -n "${DOTCONTEXT_MARKETPLACE_ROOT:-}" ] && [ -f "${DOTCONTEXT_MARKETPLACE_ROOT}/manifest.json" ]; then
    MP_MANIFEST_PATH="${DOTCONTEXT_MARKETPLACE_ROOT}/manifest.json"
    echo "$MP_MANIFEST_PATH"; return 0
  fi

  # 3. Cache
  local cache_dir="$HOME/.dotcontext/cache"
  local cache_path="$cache_dir/manifest.json"
  if [ -f "$cache_path" ] && [ "${DOTCONTEXT_MARKETPLACE_NO_CACHE:-0}" != "1" ]; then
    MP_MANIFEST_PATH="$cache_path"
    echo "$MP_MANIFEST_PATH"; return 0
  fi

  # 4. Fetch and cache
  mkdir -p "$cache_dir" 2>/dev/null
  local url="${MARKETPLACE_URL}/manifest.json"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$cache_path" 2>/dev/null || true
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$cache_path" "$url" 2>/dev/null || true
  fi

  if [ -f "$cache_path" ] && [ -s "$cache_path" ]; then
    MP_MANIFEST_PATH="$cache_path"
    echo "$MP_MANIFEST_PATH"; return 0
  fi

  printf 'dotcontext: could not load manifest from %s\n' "$url" >&2
  printf 'Try: DOTCONTEXT_MARKETPLACE_ROOT=/path/to/dotcontext-marketplace dotcontext\n' >&2
  return 1
}

# Force a fresh fetch on next mp_manifest_path call. Useful for "refresh" key
# in the TUI or for diagnostics.
mp_manifest_refresh_cache() {
  rm -f "$HOME/.dotcontext/cache/manifest.json"
  MP_MANIFEST_PATH=""
  MP_MANIFEST_JSON=""
}

mp_manifest_load() {
  mp_manifest_require_jq || return 1
  local path="${1:-$(mp_manifest_path)}"
  [ -f "$path" ] || { printf 'manifest not found: %s\n' "$path" >&2; return 1; }
  MP_MANIFEST_JSON="$(cat "$path")"
  MP_MANIFEST_PATH="$path"
}

mp_manifest_ids() {
  printf '%s' "$MP_MANIFEST_JSON" | jq -r '.items[].id'
}

mp_manifest_starter_pack_ids() {
  printf '%s' "$MP_MANIFEST_JSON" | jq -r '.items[] | select(.starter_pack == true) | .id'
}

mp_manifest_field() {
  local id="$1" field="$2"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" --arg f "$field" \
    '.items[] | select(.id == $id) | .[$f] // ""'
}

mp_manifest_files() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .files // [] | .[] | "\(.src)\t\(.dest)"'
}

mp_manifest_depends_on() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .depends_on // [] | .[]'
}

mp_manifest_scopes() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .scopes_supported[]'
}

mp_manifest_default_scope() {
  local id="$1"
  local s
  s="$(printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .default_scope // empty')"
  if [ -z "$s" ]; then
    s="$(printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
      '.items[] | select(.id == $id) | .scopes_supported[0]')"
  fi
  echo "$s"
}

mp_manifest_pm_for_os() {
  local id="$1" os="$2"
  printf '%s' "$MP_MANIFEST_JSON" | jq -c --arg id "$id" --arg os "$os" \
    '.items[] | select(.id == $id) | .package_managers[$os] // {}'
}

mp_manifest_mcp_config() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -c --arg id "$id" \
    '.items[] | select(.id == $id) | .mcp_config // {}'
}

# Returns mcp_key if set in the manifest, else id.
mp_manifest_mcp_key() {
  local id="$1" key
  key="$(printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .mcp_key // empty')"
  if [ -z "$key" ]; then
    echo "$id"
  else
    echo "$key"
  fi
}

mp_manifest_settings_keys() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .settings_keys // [] | .[]'
}

mp_manifest_auth_required() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .auth_required // false'
}

mp_manifest_verify_command() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .verify_command // ""'
}

mp_manifest_auth_command() {
  local id="$1"
  printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" \
    '.items[] | select(.id == $id) | .auth_command // ""'
}
