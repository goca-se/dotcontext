# ── lib/install/mcp.sh ────────────────────────────────────────────────────────
#
# MCP install/remove. Merges an entry under mcpServers.<id> in:
#   local:  <project>/.mcp.json
#   global: ~/.claude/settings.json
#
# Public API:
#   mp_install_mcp <id> <scope>
#   mp_remove_mcp  <id> <scope>

_mp_mcp_target_path() {
  local scope="$1"
  case "$scope" in
    local)
      local root
      root="$(mp_scope_root local)"
      echo "$root/.mcp.json"
      ;;
    global)
      mkdir -p "$HOME/.claude"
      echo "$HOME/.claude/settings.json"
      ;;
    *)
      printf 'mp_install_mcp: unsupported scope %s\n' "$scope" >&2
      return 1
      ;;
  esac
}

# Atomic merge of mcp entry into target JSON.
mp_install_mcp() {
  local id="$1" scope="$2"
  local target config key
  target="$(_mp_mcp_target_path "$scope")" || return 1
  config="$(mp_manifest_mcp_config "$id")"
  if [ -z "$config" ] || [ "$config" = "null" ] || [ "$config" = "{}" ]; then
    printf 'mp_install_mcp: no mcp_config for %s\n' "$id" >&2
    return 1
  fi
  key="$(mp_manifest_mcp_key "$id")"

  # Initialise file if missing.
  if [ ! -f "$target" ]; then
    printf '{}\n' > "$target"
  fi

  local merged
  merged="$(jq --arg key "$key" --argjson cfg "$config" \
    '.mcpServers = (.mcpServers // {}) | .mcpServers[$key] = $cfg' "$target")" || return 1
  local tmp="${target}.tmp.$$"
  printf '%s\n' "$merged" > "$tmp"
  mv "$tmp" "$target"

  local version
  version="$(mp_manifest_field "$id" version)"
  mp_lock_add_with_keys "$scope" "$id" "$version" "mcpServers.$key"
}

mp_remove_mcp() {
  local id="$1" scope="$2"
  local target key
  target="$(_mp_mcp_target_path "$scope")" || return 1
  key="$(mp_manifest_mcp_key "$id")"
  if [ -f "$target" ]; then
    local content
    content="$(jq --arg key "$key" 'if .mcpServers then .mcpServers |= del(.[$key]) else . end' "$target")" || return 1
    local tmp="${target}.tmp.$$"
    printf '%s\n' "$content" > "$tmp"
    mv "$tmp" "$target"
  fi
  mp_lock_remove "$scope" "$id"
}
