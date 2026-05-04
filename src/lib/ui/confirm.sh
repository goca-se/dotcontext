# ── lib/ui/confirm.sh ─────────────────────────────────────────────────────────
#
# y/N prompts. Consolidates ad-hoc confirm helpers from src/core/ui.sh.
#
# Public API:
#   ui_confirm <prompt> [default-yes|default-no]
#       Returns 0 if yes, 1 if no. Default is "no" if not specified.

ui_confirm() {
  local prompt="$1"
  local default="${2:-default-no}"
  local hint reply

  if [ "$default" = "default-yes" ]; then
    hint="[Y/n]"
  else
    hint="[y/N]"
  fi

  printf '%s %s ' "$prompt" "$hint"
  IFS= read -r reply || reply=""

  case "$reply" in
    y|Y|yes|Yes|YES) return 0 ;;
    n|N|no|No|NO) return 1 ;;
    "")
      if [ "$default" = "default-yes" ]; then
        return 0
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}
