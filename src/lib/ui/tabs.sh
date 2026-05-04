# ── lib/ui/tabs.sh ────────────────────────────────────────────────────────────
#
# Tab strip header. Caller manages active index; this renders the strip.
#
# Public API:
#   ui_tabs_render <row> <col> <active-index> <tab1> [tab2 ...]

ui_tabs_render() {
  local row="$1" col="$2" active="$3"; shift 3
  local tabs=("$@")
  local i=0 t
  printf '\033[%s;%sH\033[2K' "$row" "$col"
  for t in "${tabs[@]}"; do
    if [ "$i" -eq "$active" ]; then
      # Bold + reverse video for active tab
      printf '  \033[1;7m %s \033[0m' "$t"
    else
      printf '  \033[2m %s \033[0m' "$t"
    fi
    i=$(( i + 1 ))
  done
}
