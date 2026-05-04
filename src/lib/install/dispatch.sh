# ── lib/install/dispatch.sh ───────────────────────────────────────────────────
#
# Routes install/remove to the right handler based on item type.
#
# Public API:
#   mp_install <id> <scope>
#   mp_remove  <id> <scope>

mp_install() {
  local id="$1" scope="$2"
  local type
  type="$(mp_manifest_field "$id" type)"
  case "$type" in
    command-bundle) mp_install_files  "$id" "$scope" ;;
    skill)          mp_install_skill  "$id" "$scope" ;;
    script)         mp_install_script "$id" "$scope" ;;
    mcp)            mp_install_mcp    "$id" "$scope" ;;
    hook)           mp_install_hook   "$id" "$scope" ;;
    external-cli)   mp_install_cli    "$id" ;;
    *) printf 'mp_install: unknown type "%s" for %s\n' "$type" "$id" >&2; return 1 ;;
  esac
}

mp_remove() {
  local id="$1" scope="$2"
  local type
  type="$(mp_manifest_field "$id" type)"
  case "$type" in
    command-bundle) mp_remove_files  "$id" "$scope" ;;
    skill)          mp_remove_skill  "$id" "$scope" ;;
    script)         mp_remove_script "$id" "$scope" ;;
    mcp)            mp_remove_mcp    "$id" "$scope" ;;
    hook)           mp_remove_hook   "$id" "$scope" ;;
    external-cli)   mp_remove_cli    "$id" ;;
    *) printf 'mp_remove: unknown type "%s" for %s\n' "$type" "$id" >&2; return 1 ;;
  esac
}

# Bulk install (used by starter pack flow). Stops on first failure.
mp_install_many() {
  local scope="$1"; shift
  local id rc=0
  for id in "$@"; do
    if ! mp_install "$id" "$scope"; then
      printf 'install failed for %s\n' "$id" >&2
      rc=1
    fi
  done
  return $rc
}
