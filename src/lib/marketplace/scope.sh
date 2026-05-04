# ── lib/marketplace/scope.sh ──────────────────────────────────────────────────
#
# Resolves filesystem paths for a given scope.
#
# Public API:
#   mp_scope_root <scope>             # echoes the root dir (no trailing slash)
#   mp_scope_resolve <scope> <rel>    # echoes scope_root/rel
#   mp_scope_is_project_dir [path]    # exit 0 if path (default: cwd) contains .context/

mp_scope_root() {
  local scope="$1"
  case "$scope" in
    local)
      local d="$PWD"
      while [ "$d" != "/" ] && [ -n "$d" ]; do
        if [ -d "$d/.context" ]; then echo "$d"; return 0; fi
        d="$(dirname "$d")"
      done
      echo "$PWD"
      ;;
    global)
      echo "$HOME"
      ;;
    machine)
      echo ""  # no root — handled by package manager
      ;;
    *)
      printf 'mp_scope_root: unknown scope %s\n' "$scope" >&2
      return 1
      ;;
  esac
}

mp_scope_resolve() {
  local scope="$1" rel="$2"
  local root
  root="$(mp_scope_root "$scope")" || return 1
  if [ "$scope" = "global" ]; then
    # `dest` paths in manifest assume project root (e.g., ".claude/commands/..").
    # For global scope, drop the leading ".claude/" — global scope writes to
    # ~/.claude/... so we want the leading directory normalized.
    case "$rel" in
      .claude/*) echo "$root/$rel" ;;
      *)         echo "$root/$rel" ;;
    esac
  else
    echo "$root/$rel"
  fi
}

mp_scope_is_project_dir() {
  local p="${1:-$PWD}"
  [ -d "$p/.context" ]
}
