#!/usr/bin/env bash
# Combined manual smoke test for src/lib/ui/* primitives.
#
# Usage: bash tests/ui/demo.sh
#
# Renders a tab strip + a paginated multi-select list with checkbox toggling.
# Press: ↑/↓ navigate, space toggle, tab/shift-tab change tab, q quit.
#
# This demo proves the primitives compose together — it isn't shipped to users.

set -eu
HERE="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck source=/dev/null
. "$HERE/src/lib/ui/menu_paginated.sh"
# shellcheck source=/dev/null
. "$HERE/src/lib/ui/multi_select.sh"
# shellcheck source=/dev/null
. "$HERE/src/lib/ui/detail_pane.sh"
# shellcheck source=/dev/null
. "$HERE/src/lib/ui/tabs.sh"

ITEMS=(
  "code-review            Multi-agent review (3 agents)"
  "fix-bug                Test-driven bug fixing (5 agents)"
  "create-pr              PR with platform detection"
  "pr-comment             Comment on existing PRs"
  "generate-prp           Plan a feature with a PRP"
  "execute-prp            Implement a planned PRP"
  "atlassian-mcp          Jira + Confluence via OAuth"
  "grafana-mcp            Dashboards + queries"
  "context7-mcp           Up-to-date library docs"
  "gh-cli                 GitHub CLI"
  "glab-cli               GitLab CLI"
  "statusline             Custom status line"
  "notification-hook      Desktop notifications on Stop"
)
TOTAL=${#ITEMS[@]}

ui_select_init "$TOTAL"

selected=0
active_tab=0
TABS=("Browse" "Installed" "Status")

render() {
  ui_menu_clear_screen
  ui_tabs_render 1 1 "$active_tab" "${TABS[@]}"
  ui_menu_move_cursor 3 1
  printf '──── Browse ────'

  local th
  th=$(ui_menu_term_height)
  local page=$(( th - 8 ))
  [ "$page" -lt 5 ] && page=5
  local first
  first=$(ui_menu_first_visible "$selected" "$page" "$TOTAL")

  local i row=4
  for (( i = first; i < first + page && i < TOTAL; i++ )); do
    ui_menu_move_cursor "$row" 1
    local marker
    if [ "$i" -eq "$selected" ]; then marker="❯"; else marker=" "; fi
    printf '%s %s %s' "$marker" "$(ui_select_box "$i")" "${ITEMS[$i]}"
    row=$(( row + 1 ))
  done

  local fr=$(( th - 1 ))
  ui_menu_move_cursor "$fr" 1
  printf '↑↓ navigate · space toggle · tab switch tab · q quit  (selected: %s)' "$(ui_select_count)"
}

ui_menu_init
render

while :; do
  key=$(ui_menu_read_key) || break
  case "$key" in
    UP)    if [ "$selected" -gt 0 ]; then selected=$(( selected - 1 )); fi ;;
    DOWN)  if [ "$selected" -lt $(( TOTAL - 1 )) ]; then selected=$(( selected + 1 )); fi ;;
    SPACE) ui_select_toggle "$selected" ;;
    TAB)   active_tab=$(( (active_tab + 1) % ${#TABS[@]} )) ;;
    STAB)  active_tab=$(( (active_tab - 1 + ${#TABS[@]}) % ${#TABS[@]} )) ;;
    q|ESC) break ;;
  esac
  render
done

ui_menu_cleanup
echo "Selected count: $(ui_select_count)"
