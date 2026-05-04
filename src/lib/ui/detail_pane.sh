# ── lib/ui/detail_pane.sh ─────────────────────────────────────────────────────
#
# Renders a side panel describing the focused item. Bash 3.2+.
#
# Public API:
#   ui_detail_render <row> <col> <width> <height> <title> <body...>
#       — draws a simple bordered box at (row, col) with the title and a body
#         that wraps to width, truncated at height.
#
# This is intentionally minimal — orchestrator passes formatted lines.

ui_detail_render() {
  local row="$1" col="$2" width="$3" height="$4" title="$5"; shift 5
  local body_lines=("$@")

  # Title row
  printf '\033[%s;%sH' "$row" "$col"
  printf '\033[1m%s\033[0m' "$(ui_detail_truncate "$title" "$width")"

  # Separator
  printf '\033[%s;%sH' "$(( row + 1 ))" "$col"
  ui_detail_hline "$width"

  # Body
  local r=$(( row + 2 ))
  local available=$(( height - 2 ))
  local printed=0
  local ln
  for ln in "${body_lines[@]}"; do
    [ "$printed" -ge "$available" ] && break
    printf '\033[%s;%sH' "$r" "$col"
    printf '\033[2K%s' "$(ui_detail_truncate "$ln" "$width")"
    r=$(( r + 1 ))
    printed=$(( printed + 1 ))
  done
  # Pad remaining rows so leftover from a previous render is wiped.
  while [ "$printed" -lt "$available" ]; do
    printf '\033[%s;%sH\033[2K' "$r" "$col"
    r=$(( r + 1 ))
    printed=$(( printed + 1 ))
  done
}

ui_detail_truncate() {
  local s="$1" max="$2"
  if [ "${#s}" -le "$max" ]; then
    printf '%s' "$s"
  else
    local ellipsis_len=1
    local cut=$(( max - ellipsis_len ))
    [ "$cut" -lt 1 ] && cut=1
    printf '%s…' "${s:0:$cut}"
  fi
}

ui_detail_hline() {
  local w="$1" line="" i
  for (( i = 0; i < w; i++ )); do line="${line}─"; done
  printf '%s' "$line"
}
