# ── lib/ui/menu_paginated.sh ──────────────────────────────────────────────────
#
# Paginated menu with arrow navigation. Bash 3.2+.
#
# Public API:
#   ui_menu_init              # enter alt-screen, hide cursor, set raw mode
#   ui_menu_term_height       # echoes terminal height (lines)
#   ui_menu_term_width        # echoes terminal width (cols)
#   ui_menu_read_key          # blocking read of one key; echoes a name (UP/DOWN/LEFT/RIGHT/SPACE/ENTER/TAB/STAB/ESC/q/g/l/i/u/h/?/...)
#   ui_menu_cleanup           # restore screen, cursor, mode (idempotent)
#   ui_menu_save_cursor / ui_menu_restore_cursor
#   ui_menu_clear_screen      # clears alt-screen
#   ui_menu_move_cursor row col
#
# Notes:
#   - ESC followed by [ then A/B/C/D maps to UP/DOWN/RIGHT/LEFT.
#   - Bare ESC returns "ESC" (after a 1-second timeout).
#   - Tab returns "TAB", Shift-Tab returns "STAB".
#   - Bash 3.2 only supports integer `read -t`. Bare ESC therefore has a 1s
#     lag before resolving; arrow keys resolve instantly because the trailing
#     bytes are already buffered when ESC arrives.

# Capability / state ----------------------------------------------------------

UI_MENU_ALT_ACTIVE=0
UI_MENU_ORIG_STTY=""

ui_menu_supports_alt_screen() {
  command -v tput >/dev/null 2>&1 || return 1
  tput smcup >/dev/null 2>&1
}

ui_menu_term_height() {
  local h
  h=$(tput lines 2>/dev/null || echo "")
  if [ -z "$h" ] || [ "$h" -lt 10 ] 2>/dev/null; then h=24; fi
  echo "$h"
}

ui_menu_term_width() {
  local w
  w=$(tput cols 2>/dev/null || echo "")
  if [ -z "$w" ] || [ "$w" -lt 40 ] 2>/dev/null; then w=80; fi
  echo "$w"
}

# Setup / teardown ------------------------------------------------------------

ui_menu_init() {
  UI_MENU_ORIG_STTY=$(stty -g 2>/dev/null || echo "")
  stty -echo 2>/dev/null || true
  if ui_menu_supports_alt_screen; then
    tput smcup
    UI_MENU_ALT_ACTIVE=1
  else
    printf '\n'
  fi
  tput civis 2>/dev/null || printf '\033[?25l'
  trap 'ui_menu_cleanup' EXIT INT TERM
}

ui_menu_cleanup() {
  tput cnorm 2>/dev/null || printf '\033[?25h'
  if [ "$UI_MENU_ALT_ACTIVE" -eq 1 ]; then
    tput rmcup
    UI_MENU_ALT_ACTIVE=0
  fi
  if [ -n "$UI_MENU_ORIG_STTY" ]; then
    stty "$UI_MENU_ORIG_STTY" 2>/dev/null || stty echo 2>/dev/null || true
  else
    stty echo 2>/dev/null || true
  fi
}

# Cursor / screen helpers -----------------------------------------------------

ui_menu_clear_screen() { printf '\033[2J\033[H'; }
ui_menu_move_cursor()  { printf '\033[%s;%sH' "$1" "$2"; }
ui_menu_save_cursor()  { printf '\033[s'; }
ui_menu_restore_cursor() { printf '\033[u'; }
ui_menu_clear_line()   { printf '\033[2K'; }

# Key reading -----------------------------------------------------------------

# Reads one logical key. Echoes a stable name.
#
# Bash 3.2 caveat: `read -t` only accepts INTEGER seconds (fractional was added
# in bash 4.0). macOS ships 3.2.57, so we use `-t 1`. After an ESC, an arrow
# key's remaining bytes are already buffered, so `read` returns immediately —
# the 1s only fires for a bare ESC press, which is acceptable lag.
ui_menu_read_key() {
  local k1 rest
  IFS= read -rsn1 k1 || return 1
  case "$k1" in
    "")          echo "ENTER"; return 0 ;;
    $'\n')       echo "ENTER"; return 0 ;;
    $'\r')       echo "ENTER"; return 0 ;;
    " ")         echo "SPACE"; return 0 ;;
    $'\t')       echo "TAB"; return 0 ;;
    $'\033')
      # Read up to 2 more chars in one syscall. Buffered escape sequences
      # (`[A`, `[B`, ..., `OA`, `[Z`) come back instantly.
      rest=""
      IFS= read -rsn2 -t 1 rest 2>/dev/null
      case "$rest" in
        "[A"|"OA") echo "UP";    return 0 ;;
        "[B"|"OB") echo "DOWN";  return 0 ;;
        "[C"|"OC") echo "RIGHT"; return 0 ;;
        "[D"|"OD") echo "LEFT";  return 0 ;;
        "[Z")      echo "STAB";  return 0 ;;
        *)         echo "ESC";   return 0 ;;
      esac
      ;;
    *) echo "$k1"; return 0 ;;
  esac
}

# Pagination math -------------------------------------------------------------

# Compute first visible index given:
#   $1 = selected (0-based)
#   $2 = page_size
#   $3 = total
ui_menu_first_visible() {
  local sel="$1" page="$2" total="$3"
  local first=0
  if [ "$total" -le "$page" ]; then
    echo 0; return 0
  fi
  first=$(( sel - page / 2 ))
  [ "$first" -lt 0 ] && first=0
  if [ $(( first + page )) -gt "$total" ]; then
    first=$(( total - page ))
  fi
  echo "$first"
}
