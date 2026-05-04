# ── lib/install/script.sh ─────────────────────────────────────────────────────
#
# Standalone script install/remove (statusline.sh, etc). After file copy,
# chmod +x. Settings keys (e.g., statusLine pointer) are merged in mcp.sh's
# helpers shared by hook handlers.

mp_install_script() {
  local id="$1" scope="$2"
  mp_install_files "$id" "$scope" || return 1
  # Chmod +x for any installed file under .claude/scripts/.
  local root path f
  root="$(mp_scope_root "$scope")"
  path="$(mp_lock_path "$scope")"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      *.sh|*.py|*scripts/*) chmod +x "$root/$f" 2>/dev/null || true ;;
    esac
  done <<EOF
$(jq -r --arg id "$id" '.items[] | select(.id == $id) | .files // [] | .[]' "$path")
EOF
}

mp_remove_script() { mp_remove_files "$@"; }
