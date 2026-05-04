# ── lib/ui/multi_select.sh ────────────────────────────────────────────────────
#
# State tracking for multi-select lists. Bash 3.2 (no assoc arrays).
#
# Selection is stored in a parallel boolean array UI_SEL_STATE, indexed by item
# position. Callers populate item arrays themselves; this file only manages
# selection, focus, and rendering of checkbox glyphs.
#
# Public API:
#   ui_select_init <count>           # zero out selection state for N items
#   ui_select_toggle <index>         # flip item at index
#   ui_select_set <index> <0|1>
#   ui_select_get <index>            # echoes 0 or 1
#   ui_select_count                  # echoes number selected
#   ui_select_box <index>            # echoes "[x]" or "[ ]" for rendering
#   ui_select_select_all <count>
#   ui_select_clear_all <count>

# Indexed array; parallel to caller's items.
UI_SEL_STATE=()

ui_select_init() {
  local n="$1" i
  UI_SEL_STATE=()
  for (( i = 0; i < n; i++ )); do
    UI_SEL_STATE[$i]=0
  done
}

ui_select_toggle() {
  local idx="$1"
  if [ "${UI_SEL_STATE[$idx]:-0}" = "1" ]; then
    UI_SEL_STATE[$idx]=0
  else
    UI_SEL_STATE[$idx]=1
  fi
}

ui_select_set() {
  local idx="$1" val="$2"
  UI_SEL_STATE[$idx]="$val"
}

ui_select_get() {
  local idx="$1"
  echo "${UI_SEL_STATE[$idx]:-0}"
}

ui_select_count() {
  local i count=0
  for i in "${UI_SEL_STATE[@]}"; do
    [ "$i" = "1" ] && count=$(( count + 1 ))
  done
  echo "$count"
}

ui_select_box() {
  local idx="$1"
  if [ "${UI_SEL_STATE[$idx]:-0}" = "1" ]; then
    echo "[x]"
  else
    echo "[ ]"
  fi
}

ui_select_select_all() {
  local n="$1" i
  for (( i = 0; i < n; i++ )); do
    UI_SEL_STATE[$i]=1
  done
}

ui_select_clear_all() {
  local n="$1" i
  for (( i = 0; i < n; i++ )); do
    UI_SEL_STATE[$i]=0
  done
}
