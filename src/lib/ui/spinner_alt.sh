# ── lib/ui/spinner_alt.sh ─────────────────────────────────────────────────────
#
# Spinner that coexists with alt-screen (lib/ui/menu_paginated.sh). Renders at
# a fixed (row, col) without disturbing other regions.
#
# Public API:
#   ui_spinner_alt_start <row> <col> <message>
#   ui_spinner_alt_stop  [final-message]
#
# Differences from src/core/spinner.sh:
#   - absolute-position render (won't overwrite list rows)
#   - clears its row on stop
#   - safe to call from inside an alt-screen session

UI_SPINNER_ALT_PID=""
UI_SPINNER_ALT_ROW=""
UI_SPINNER_ALT_COL=""

ui_spinner_alt_start() {
  local row="$1" col="$2" msg="$3"
  UI_SPINNER_ALT_ROW="$row"
  UI_SPINNER_ALT_COL="$col"
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  (
    local i=0
    while true; do
      printf '\033[s\033[%s;%sH\033[2K\033[34m%s\033[0m %s\033[u' \
        "$row" "$col" "${frames[$i]}" "$msg"
      i=$(( (i + 1) % 10 ))
      sleep 0.1
    done
  ) &
  UI_SPINNER_ALT_PID=$!
  disown 2>/dev/null || true
}

ui_spinner_alt_stop() {
  local final="${1:-}"
  if [ -n "$UI_SPINNER_ALT_PID" ]; then
    kill "$UI_SPINNER_ALT_PID" 2>/dev/null
    wait "$UI_SPINNER_ALT_PID" 2>/dev/null || true
    UI_SPINNER_ALT_PID=""
  fi
  if [ -n "$UI_SPINNER_ALT_ROW" ] && [ -n "$UI_SPINNER_ALT_COL" ]; then
    printf '\033[s\033[%s;%sH\033[2K' "$UI_SPINNER_ALT_ROW" "$UI_SPINNER_ALT_COL"
    if [ -n "$final" ]; then
      printf '%s' "$final"
    fi
    printf '\033[u'
  fi
  UI_SPINNER_ALT_ROW=""
  UI_SPINNER_ALT_COL=""
}
