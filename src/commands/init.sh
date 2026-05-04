# ── Command: init ─────────────────────────────────────────────────────────────
#
# Creates Layer 1 only: the absolute minimum to bootstrap the methodology —
# `.context/` skeleton, CLAUDE.md, .claudeignore, and `/setup-context`.
#
# Everything else (including /add-decision, /add-skill, /add-command, /commit,
# /deep-context, /code-review, /fix-bug, /create-pr, /pr-comment, /generate-prp,
# /execute-prp, MCPs, CLIs, statusline, notification hook) is Layer 2 —
# installed on-demand via the marketplace TUI (run `dotcontext` no-args).
#
# See ADR-015 v3.0 (Two-Layer Distribution Model — strict rule).

cmd_init() {
  local project_name=""
  local skip_prompts=false
  local skip_setup=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name) project_name="$2"; shift 2 ;;
      -y|--yes) skip_prompts=true; shift ;;
      --no-setup) skip_setup=true; shift ;;
      *) shift ;;
    esac
  done

  print_blue ""
  printf "${BLUE}📁 dotcontext - AI Context Toolkit${NC}\n\n"

  local cwd="$(pwd)"

  local is_reinit=false
  if [ -d ".context" ]; then
    is_reinit=true
    print_yellow "Existing .context/ detected — will add missing files without overwriting your content."
  fi

  if [ -z "$project_name" ]; then
    if [ "$skip_prompts" = false ]; then
      project_name=$(prompt "Project name" "$(basename "$cwd")")
    else
      project_name="$(basename "$cwd")"
    fi
  fi

  print_gray "Creating Layer 1 structure..."

  # Create directories (mkdir -p is always safe).
  mkdir -p ".context/decisions"
  mkdir -p ".context/prp/templates"
  mkdir -p ".context/prp/generated"
  mkdir -p ".context/discoveries"
  mkdir -p ".context/bugs"
  mkdir -p ".claude/commands"

  # Download templates.
  start_spinner "Downloading Layer 1..."

  # Helper: download only if file doesn't exist (for seed/user-customizable).
  local skipped_files=""
  download_if_missing() {
    local url="$1"
    local target="$2"
    if [ -f "$target" ]; then
      if [ "$is_reinit" = true ]; then
        skipped_files="${skipped_files}${target}\n"
      fi
      return 0
    fi
    download "$url" "$target"
  }

  # Seed files: user-customizable content — only created if missing.
  download_if_missing "${BASE_URL}/templates/.claudeignore" ".claudeignore"
  download_if_missing "${BASE_URL}/templates/CLAUDE.md" "CLAUDE.md"
  download_if_missing "${BASE_URL}/templates/.context/CONTEXT.md" ".context/CONTEXT.md"
  download_if_missing "${BASE_URL}/templates/.context/decisions/README.md" ".context/decisions/README.md"
  download_if_missing "${BASE_URL}/templates/.context/prp/templates/feature.md" ".context/prp/templates/feature.md"

  # The single Layer 1 command (managed — always downloaded, safe to overwrite).
  download "${BASE_URL}/templates/.claude/commands/setup-context.md" ".claude/commands/setup-context.md"

  stop_spinner

  if [ -n "$skipped_files" ]; then
    printf "$skipped_files" | while read -r f; do
      [ -n "$f" ] && print_gray "  skipped (exists): $f"
    done
  fi

  touch ".context/prp/generated/.keep"
  touch ".context/discoveries/.keep"
  touch ".context/bugs/.keep"

  # Substitute project name (only on fresh CLAUDE.md with placeholder).
  if grep -q "{{projectName}}" "CLAUDE.md" 2>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/{{projectName}}/$project_name/g" "CLAUDE.md"
    else
      sed -i "s/{{projectName}}/$project_name/g" "CLAUDE.md"
    fi
  fi

  echo ""
  if [ "$is_reinit" = true ]; then
    printf "  ${GREEN}${ICON_SUCCESS}${NC} Methodology updated\n"
  else
    printf "  ${GREEN}${ICON_SUCCESS}${NC} Methodology installed\n"
  fi
  printf "  ${GRAY}CLAUDE.md  .context/  .claude/commands/setup-context.md${NC}\n"
  echo ""
  printf "  ${BOLD}Next:${NC}\n"
  printf "  ${GRAY}•${NC} ${CYAN}/setup-context${NC} populates context (auto-running now)\n"
  printf "  ${GRAY}•${NC} Then run ${CYAN}dotcontext${NC} in a regular terminal to browse the marketplace\n"
  printf "    ${GRAY}(interactive TUIs don't render inside Claude Code's ${CYAN}!${GRAY} bash block)${NC}\n"
  printf "  ${GRAY}•${NC} Press ${BOLD}P${NC} in the TUI to install the starter pack (16 items)\n"
  echo ""

  if [ "$skip_setup" = true ]; then
    printf "  ${CYAN}Skipped:${NC}  run ${CYAN}/setup-context${NC} manually in Claude Code when ready\n"
  else
    if command -v claude &> /dev/null; then
      printf "  ${CYAN}Running /setup-context...${NC}\n\n"
      claude "/setup-context"
    else
      printf "  ${YELLOW}Claude CLI not found.${NC} Run ${CYAN}/setup-context${NC} manually in Claude Code.\n"
    fi
  fi
  echo ""
}
