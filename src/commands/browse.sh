# ── Command: browse (internal — invoked when dotcontext gets no args) ─────────
#
# Marketplace TUI with 3 tabs: Browse · Installed · Status.
# Bash 3.2 compatible. Uses src/lib/ui/* primitives.

# Keep entry point exported so main.sh can call it.
cmd_browse() {
  # TUIs are full of conditional logic that returns non-zero benignly
  # (lockfile entry not found, scope not yet set, arithmetic landing on 0,
  # etc.). The rest of dotcontext runs under `set -e` from header.sh, but
  # for the marketplace TUI we want soft errors. Optional trace via
  # DOTCONTEXT_DEBUG=1 to a file.
  set +e
  if [ "${DOTCONTEXT_DEBUG:-0}" = "1" ]; then
    exec 4>>/tmp/dotcontext-tui.log
    BASH_XTRACEFD=4
    PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
    set -x
  fi

  if ! mp_manifest_load 2>/dev/null; then
    print_red "dotcontext: marketplace TUI requires jq."
    print_yellow "Install: brew install jq | sudo apt-get install jq | sudo dnf install jq"
    exit 1
  fi

  # Per-item parallel arrays (indexed same as BROWSE_IDS).
  BROWSE_IDS=()
  BROWSE_NAMES=()
  BROWSE_DESCS=()
  BROWSE_CATS=()
  BROWSE_SCOPES=()      # current scope choice for *action* per item
  BROWSE_INSTALLED=()   # actual installed scope: "" | "local" | "global" | "machine" | "local+global"

  _browse_load_items
  _browse_load_installed_state
  ui_select_init "${#BROWSE_IDS[@]}"

  active_tab=0
  selected=0
  TABS=("Browse" "Installed" "Status")

  ui_menu_init
  trap '_browse_quit' EXIT INT TERM
  _browse_render

  while :; do
    key="$(ui_menu_read_key)" || break
    case "$active_tab" in
      0) _browse_handle_browse "$key" || break ;;
      1) _browse_handle_installed "$key" || break ;;
      2) _browse_handle_status "$key" || break ;;
    esac
    _browse_render
  done

  _browse_quit
}

_browse_quit() {
  ui_menu_cleanup
  exit 0
}

_browse_load_items() {
  local id name desc cat default_scope
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    name="$(mp_manifest_field "$id" name)"
    desc="$(mp_manifest_field "$id" description)"
    cat="$(mp_manifest_field "$id" category)"
    default_scope="$(mp_manifest_default_scope "$id")"
    BROWSE_IDS+=("$id")
    BROWSE_NAMES+=("$name")
    BROWSE_DESCS+=("$desc")
    BROWSE_CATS+=("$cat")
    BROWSE_SCOPES+=("$default_scope")
    BROWSE_INSTALLED+=("")
  done <<EOF
$(mp_manifest_ids)
EOF
}

# Re-scan the lockfiles and update BROWSE_INSTALLED. Called once at startup
# and again after install/uninstall so the UI stays in sync without a restart.
_browse_load_installed_state() {
  local i id state
  for (( i = 0; i < ${#BROWSE_IDS[@]}; i++ )); do
    id="${BROWSE_IDS[$i]}"
    state=""
    if mp_lock_has local "$id" 2>/dev/null; then state="local"; fi
    if mp_lock_has global "$id" 2>/dev/null; then
      if [ -n "$state" ]; then state="local+global"; else state="global"; fi
    fi
    if mp_lock_has machine "$id" 2>/dev/null; then state="machine"; fi
    BROWSE_INSTALLED[$i]="$state"
    # If installed in a single scope, snap the action scope to match — so the
    # user sees "this is what would be reinstalled" rather than the default.
    case "$state" in
      local|global|machine) BROWSE_SCOPES[$i]="$state" ;;
    esac
  done
}

# ── Render ──────────────────────────────────────────────────────────────────

# Flicker-free render via atomic frame: every escape + content for the new
# frame is captured into a single string in a subshell, then flushed in one
# write. Terminals commit display per write, so a single big write looks
# atomic to the eye — no visible cascade or full-screen flash.
#
# Bash 3.2 caveat: a `case` statement inside `$( ... )` confuses the parser
# (it treats the `)` of a case pattern as closing the command substitution).
# Workaround: keep the case in a regular function and only call it from $().
_browse_render_frame() {
  printf '\033[H'
  ui_tabs_render 1 1 "$active_tab" "${TABS[@]}"
  case "$active_tab" in
    0) _browse_render_browse ;;
    1) _browse_render_installed ;;
    2) _browse_render_status ;;
  esac
  _browse_render_footer
}

_browse_render() {
  local frame
  frame="$(_browse_render_frame)"
  printf '%s' "$frame"
}

# Wipes rows from <start_row> up to (but not including) the footer row.
# Used by tab renderers to clear leftover content from a previous render
# that wrote more rows than the current one.
_browse_clear_rows_below() {
  local start_row="$1"
  local th r footer
  th="$(ui_menu_term_height)"
  footer=$(( th - 2 ))
  r="$start_row"
  while [ "$r" -le "$footer" ]; do
    printf '\033[%s;1H\033[2K' "$r"
    r=$(( r + 1 ))
  done
}

_browse_render_footer() {
  local th
  th="$(ui_menu_term_height)"
  local fr=$(( th - 1 ))
  ui_menu_move_cursor "$fr" 1
  printf '\033[2K'
  case "$active_tab" in
    0) printf '↑↓ nav · space toggle · g/l scope · p starter pack · i install · tab next · q quit' ;;
    1) printf '↑↓ nav · u uninstall focused · tab next · q quit' ;;
    2) printf 'tab next · q quit' ;;
  esac
}

# ── Browse tab ──────────────────────────────────────────────────────────────

_browse_render_browse() {
  local row=3 sp_count
  sp_count="$(mp_manifest_starter_pack_ids | wc -l | tr -d ' ')"
  ui_menu_move_cursor "$row" 1
  printf '\033[2K\033[1m★ Install starter pack (%s items)\033[0m   \033[2m[press p]\033[0m' "$sp_count"
  row=$(( row + 1 ))
  ui_menu_move_cursor "$row" 1; printf '\033[2K'
  row=$(( row + 1 ))

  local th page first total
  total=${#BROWSE_IDS[@]}
  th="$(ui_menu_term_height)"
  page=$(( th - 8 ))
  [ "$page" -lt 5 ] && page=5
  first="$(ui_menu_first_visible "$selected" "$page" "$total")"

  local i last_cat=""
  for (( i = first; i < first + page && i < total; i++ )); do
    if [ "${BROWSE_CATS[$i]}" != "$last_cat" ]; then
      ui_menu_move_cursor "$row" 1
      printf '\033[2K\033[34m%s\033[0m' "${BROWSE_CATS[$i]}"
      last_cat="${BROWSE_CATS[$i]}"
      row=$(( row + 1 ))
      [ "$row" -ge $(( th - 2 )) ] && break
    fi
    ui_menu_move_cursor "$row" 1
    printf '\033[2K'
    local marker installed_marker scope_tag
    if [ "$i" -eq "$selected" ]; then marker="❯"; else marker=" "; fi
    case "${BROWSE_INSTALLED[$i]}" in
      "")            installed_marker=" " ;;
      *)             installed_marker=$'\033[32m✓\033[0m' ;;
    esac
    case "${BROWSE_INSTALLED[$i]:-${BROWSE_SCOPES[$i]}}" in
      local)         scope_tag=$'\033[36m[L]\033[0m' ;;
      global)        scope_tag=$'\033[35m[G]\033[0m' ;;
      machine)       scope_tag=$'\033[33m[M]\033[0m' ;;
      "local+global") scope_tag=$'\033[35m[L+G]\033[0m' ;;
      *)             scope_tag="[?]" ;;
    esac
    printf ' %s %s %s %s %-22s %s' "$marker" "$installed_marker" \
      "$(ui_select_box "$i")" "$scope_tag" \
      "${BROWSE_IDS[$i]}" "${BROWSE_DESCS[$i]}"
    row=$(( row + 1 ))
  done

  _browse_clear_rows_below "$row"
}

_browse_handle_browse() {
  local key="$1"
  local total=${#BROWSE_IDS[@]}
  case "$key" in
    UP)    [ "$selected" -gt 0 ] && selected=$(( selected - 1 )) ;;
    DOWN)  [ "$selected" -lt $(( total - 1 )) ] && selected=$(( selected + 1 )) ;;
    SPACE) ui_select_toggle "$selected" ;;
    g|G)   _browse_set_scope "$selected" global ;;
    l|L)   _browse_set_scope "$selected" local ;;
    p|P)   _browse_select_starter_pack ;;
    i|I)   _browse_install_selected ;;
    TAB)   active_tab=$(( (active_tab + 1) % 3 )) ;;
    STAB)  active_tab=$(( (active_tab + 2) % 3 )) ;;
    q|Q|ESC) return 1 ;;
  esac
  return 0
}

_browse_set_scope() {
  local idx="$1" wanted="$2"
  local id="${BROWSE_IDS[$idx]}"
  local supported
  supported="$(mp_manifest_scopes "$id" | tr '\n' ' ')"
  case " $supported " in
    *" $wanted "*) BROWSE_SCOPES[$idx]="$wanted" ;;
  esac
}

_browse_select_starter_pack() {
  local sp_ids="$(mp_manifest_starter_pack_ids)"
  local id i
  for (( i = 0; i < ${#BROWSE_IDS[@]}; i++ )); do
    id="${BROWSE_IDS[$i]}"
    if echo "$sp_ids" | grep -qx "$id"; then
      ui_select_set "$i" 1
    fi
  done
}

_browse_install_selected() {
  ui_menu_cleanup
  echo
  print_blue "Installing selected items..."
  echo

  local i id scope type rc=0 installed_count=0
  for (( i = 0; i < ${#BROWSE_IDS[@]}; i++ )); do
    if [ "$(ui_select_get "$i")" = "1" ]; then
      id="${BROWSE_IDS[$i]}"
      scope="${BROWSE_SCOPES[$i]}"
      type="$(mp_manifest_field "$id" type)"

      if [ "$type" = "external-cli" ]; then
        # External CLIs install via OS package manager (brew/apt/dnf/...) and
        # *need* visible output: the handler prints a confirm prompt + runs
        # the package manager (which itself prints progress). Don't redirect.
        echo
        printf '  ${BOLD}• %s (%s)${NC} — installs system-wide via package manager\n' "$id" "$scope"
        if mp_install "$id" "$scope"; then
          ui_select_set "$i" 0
          installed_count=$(( installed_count + 1 ))
          print_green "    ✓ $id installed"
        else
          print_yellow "    ⚠ $id skipped or failed (continuing)"
        fi
      else
        # File-based items (command-bundle / skill / mcp / hook / script) are
        # quiet; we just need OK/FAIL feedback.
        printf '  • %s (%s)... ' "$id" "$scope"
        if mp_install "$id" "$scope" >/dev/null 2>&1; then
          print_green "OK"
          ui_select_set "$i" 0
          installed_count=$(( installed_count + 1 ))
        else
          print_red "FAIL"
          rc=1
        fi
      fi
    fi
  done

  echo
  if [ "$rc" -eq 0 ]; then
    print_green "Installed $installed_count item(s)."
  else
    print_yellow "Some installs failed. Re-run dotcontext to retry."
  fi
  echo
  printf 'Press enter to return to TUI...'
  IFS= read -r _ || true
  ui_menu_init
  _browse_load_installed_state   # refresh ✓ markers
}

# ── Installed tab ───────────────────────────────────────────────────────────

INSTALLED_IDS=()
INSTALLED_SCOPES=()
INSTALLED_FOCUS=0

_browse_load_installed() {
  INSTALLED_IDS=()
  INSTALLED_SCOPES=()
  local id
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    INSTALLED_IDS+=("$id")
    INSTALLED_SCOPES+=("local")
  done <<EOF
$(mp_lock_list_ids local)
EOF
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    INSTALLED_IDS+=("$id")
    INSTALLED_SCOPES+=("global")
  done <<EOF
$(mp_lock_list_ids global)
EOF
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    INSTALLED_IDS+=("$id")
    INSTALLED_SCOPES+=("machine")
  done <<EOF
$(mp_lock_list_ids machine)
EOF
}

_browse_render_installed() {
  _browse_load_installed
  local row=3
  ui_menu_move_cursor "$row" 1
  printf '\033[2K\033[1mInstalled items\033[0m'
  row=$(( row + 1 ))
  ui_menu_move_cursor "$row" 1; printf '\033[2K'
  row=$(( row + 1 ))

  local total=${#INSTALLED_IDS[@]}
  if [ "$total" -eq 0 ]; then
    ui_menu_move_cursor "$row" 1
    printf '\033[2K\033[2m  (nothing tracked yet — install items from Browse)\033[0m'
    row=$(( row + 1 ))
    _browse_clear_rows_below "$row"
    return
  fi

  [ "$INSTALLED_FOCUS" -ge "$total" ] && INSTALLED_FOCUS=0

  local th page first
  th="$(ui_menu_term_height)"
  page=$(( th - 7 ))
  [ "$page" -lt 5 ] && page=5
  first="$(ui_menu_first_visible "$INSTALLED_FOCUS" "$page" "$total")"

  local i marker
  for (( i = first; i < first + page && i < total; i++ )); do
    ui_menu_move_cursor "$row" 1
    printf '\033[2K'
    if [ "$i" -eq "$INSTALLED_FOCUS" ]; then marker="❯"; else marker=" "; fi
    printf ' %s [%-7s] %s' "$marker" "${INSTALLED_SCOPES[$i]}" "${INSTALLED_IDS[$i]}"
    row=$(( row + 1 ))
  done

  _browse_clear_rows_below "$row"
}

_browse_handle_installed() {
  local key="$1"
  local total=${#INSTALLED_IDS[@]}
  case "$key" in
    UP)    [ "$INSTALLED_FOCUS" -gt 0 ] && INSTALLED_FOCUS=$(( INSTALLED_FOCUS - 1 )) ;;
    DOWN)  [ "$INSTALLED_FOCUS" -lt $(( total - 1 )) ] && INSTALLED_FOCUS=$(( INSTALLED_FOCUS + 1 )) ;;
    u|U)   _browse_uninstall_focused ;;
    TAB)   active_tab=$(( (active_tab + 1) % 3 )) ;;
    STAB)  active_tab=$(( (active_tab + 2) % 3 )) ;;
    q|Q|ESC) return 1 ;;
  esac
  return 0
}

_browse_uninstall_focused() {
  [ "${#INSTALLED_IDS[@]}" -eq 0 ] && return 0
  local id="${INSTALLED_IDS[$INSTALLED_FOCUS]}"
  local scope="${INSTALLED_SCOPES[$INSTALLED_FOCUS]}"
  ui_menu_cleanup
  echo
  if ui_confirm "Uninstall $id ($scope)?"; then
    if mp_remove "$id" "$scope"; then
      print_green "Removed $id."
    else
      print_red "Failed to remove $id."
    fi
  fi
  echo
  printf 'Press enter...'
  IFS= read -r _ || true
  ui_menu_init
  _browse_load_installed_state   # refresh ✓ markers in Browse tab
}

# ── Status tab ──────────────────────────────────────────────────────────────

_browse_render_status() {
  local row=3
  ui_menu_move_cursor "$row" 1
  printf '\033[2K\033[1mProject health\033[0m'
  row=$(( row + 1 ))
  ui_menu_move_cursor "$row" 1; printf '\033[2K'
  row=$(( row + 1 ))

  ui_menu_move_cursor "$row" 1
  printf '\033[2K'
  if mp_scope_is_project_dir; then
    printf '  \033[32m✓\033[0m This directory is a dotcontext project (.context/ found)'
  else
    printf '  \033[33m⚠\033[0m Not a dotcontext project — only global installs available here'
  fi
  row=$(( row + 1 ))

  ui_menu_move_cursor "$row" 1
  printf '\033[2K'
  local layer1
  layer1="$(_browse_layer1_status)"
  printf '  Layer 1: %s' "$layer1"
  row=$(( row + 1 ))
  ui_menu_move_cursor "$row" 1; printf '\033[2K'
  row=$(( row + 1 ))

  ui_menu_move_cursor "$row" 1
  printf '\033[2K\033[1mInstalled MCPs\033[0m'
  row=$(( row + 1 ))
  local id mcp_count=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    if [ "$(mp_manifest_field "$id" type)" = "mcp" ]; then
      ui_menu_move_cursor "$row" 1
      printf '\033[2K'
      local auth_req
      auth_req="$(mp_manifest_auth_required "$id")"
      if [ "$auth_req" = "true" ]; then
        printf '  \033[33m?\033[0m %-20s auth via /mcp inside Claude Code' "$id"
      else
        printf '  \033[32m✓\033[0m %-20s no auth required' "$id"
      fi
      row=$(( row + 1 ))
      mcp_count=$(( mcp_count + 1 ))
    fi
  done <<EOF
$(mp_lock_list_ids global)
$(mp_lock_list_ids local)
EOF
  if [ "$mcp_count" -eq 0 ]; then
    ui_menu_move_cursor "$row" 1
    printf '\033[2K\033[2m  (none installed)\033[0m'
    row=$(( row + 1 ))
  fi

  ui_menu_move_cursor "$row" 1; printf '\033[2K'
  row=$(( row + 1 ))
  ui_menu_move_cursor "$row" 1
  printf '\033[2K\033[1mInstalled CLIs\033[0m'
  row=$(( row + 1 ))
  local cli_count=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    ui_menu_move_cursor "$row" 1
    printf '\033[2K'
    local st
    st="$(mp_cli_status "$id")"
    case "$st" in
      ok)              printf '  \033[32m✓\033[0m %-20s installed + authenticated' "$id" ;;
      unauthenticated) printf '  \033[33m⚠\033[0m %-20s installed but not authenticated' "$id" ;;
      missing)         printf '  \033[31m✗\033[0m %-20s not found on PATH' "$id" ;;
      *)               printf '  \033[2m?\033[0m %-20s %s' "$id" "$st" ;;
    esac
    row=$(( row + 1 ))
    cli_count=$(( cli_count + 1 ))
  done <<EOF
$(mp_lock_list_ids machine)
EOF
  if [ "$cli_count" -eq 0 ]; then
    ui_menu_move_cursor "$row" 1
    printf '\033[2K\033[2m  (none installed)\033[0m'
    row=$(( row + 1 ))
  fi

  _browse_clear_rows_below "$row"
}

_browse_layer1_status() {
  local root
  root="$(mp_scope_root local)"
  local missing=0
  local f
  for f in CLAUDE.md .context/CONTEXT.md .claude/commands/setup-context.md \
           .claude/commands/commit.md .claude/commands/deep-context.md; do
    [ -f "$root/$f" ] || missing=$(( missing + 1 ))
  done
  if [ "$missing" -eq 0 ]; then
    printf '\033[32m✓\033[0m all expected files present'
  else
    printf '\033[33m⚠\033[0m %d expected file(s) missing — run dotcontext init or update' "$missing"
  fi
}

_browse_handle_status() {
  local key="$1"
  case "$key" in
    TAB)  active_tab=$(( (active_tab + 1) % 3 )) ;;
    STAB) active_tab=$(( (active_tab + 2) % 3 )) ;;
    q|Q|ESC) return 1 ;;
  esac
  return 0
}
