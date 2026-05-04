# ── lib/install/hook.sh ───────────────────────────────────────────────────────
#
# Hook install/remove. Hooks are entries in settings.json under .hooks.<event>.
#
# Public API:
#   mp_install_hook <id> <scope>
#   mp_remove_hook  <id> <scope>

_mp_hook_target_path() {
  local scope="$1"
  case "$scope" in
    local)
      local root
      root="$(mp_scope_root local)"
      mkdir -p "$root/.claude" 2>/dev/null
      echo "$root/.claude/settings.json"
      ;;
    global)
      mkdir -p "$HOME/.claude"
      echo "$HOME/.claude/settings.json"
      ;;
    *)
      printf 'mp_install_hook: unsupported scope %s\n' "$scope" >&2
      return 1
      ;;
  esac
}

mp_install_hook() {
  local id="$1" scope="$2"
  local target hook_config event command
  target="$(_mp_hook_target_path "$scope")" || return 1
  hook_config="$(printf '%s' "$MP_MANIFEST_JSON" | jq -c --arg id "$id" \
    '.items[] | select(.id == $id) | .hook_config // {}')"
  [ "$hook_config" = "{}" ] || [ -z "$hook_config" ] && {
    printf 'mp_install_hook: no hook_config for %s\n' "$id" >&2
    return 1
  }
  event="$(printf '%s' "$hook_config" | jq -r '.event // ""')"
  command="$(printf '%s' "$hook_config" | jq -r '.command // ""')"
  [ -z "$event" ] || [ -z "$command" ] && {
    printf 'mp_install_hook: missing event/command in hook_config\n' >&2
    return 1
  }

  if [ ! -f "$target" ]; then
    printf '{}\n' > "$target"
  fi

  local merged
  merged="$(jq --arg ev "$event" --arg cmd "$command" \
    '
      .hooks = (.hooks // {}) |
      .hooks[$ev] = ((.hooks[$ev] // []) + [{ command: $cmd }])
    ' "$target")" || return 1
  local tmp="${target}.tmp.$$"
  printf '%s\n' "$merged" > "$tmp"
  mv "$tmp" "$target"

  local version
  version="$(mp_manifest_field "$id" version)"
  mp_lock_add_with_keys "$scope" "$id" "$version" "hooks.$event"
}

mp_remove_hook() {
  local id="$1" scope="$2"
  local target hook_config event command
  target="$(_mp_hook_target_path "$scope")" || return 1
  if [ -f "$target" ]; then
    hook_config="$(printf '%s' "$MP_MANIFEST_JSON" | jq -c --arg id "$id" \
      '.items[] | select(.id == $id) | .hook_config // {}')"
    event="$(printf '%s' "$hook_config" | jq -r '.event // ""')"
    command="$(printf '%s' "$hook_config" | jq -r '.command // ""')"

    local content
    content="$(jq --arg ev "$event" --arg cmd "$command" \
      '
        if .hooks and .hooks[$ev] then
          .hooks[$ev] |= map(select(.command != $cmd))
        else . end
      ' "$target")" || return 1
    local tmp="${target}.tmp.$$"
    printf '%s\n' "$content" > "$tmp"
    mv "$tmp" "$target"
  fi
  mp_lock_remove "$scope" "$id"
}
