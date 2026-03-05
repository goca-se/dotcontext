# ── Command: init ─────────────────────────────────────────────────────────────

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

  print_gray "Creating structure..."

  # Create directories (mkdir -p is always safe)
  mkdir -p ".context/decisions"
  mkdir -p ".claude/skills"
  mkdir -p ".claude/skills/bug-reproduction"
  mkdir -p ".context/prp/templates"
  mkdir -p ".context/prp/generated"
  mkdir -p ".context/discoveries"
  mkdir -p ".context/bugs"
  mkdir -p ".claude/commands"
  mkdir -p ".claude/scripts"
  mkdir -p ".claude/agents/code-review"
  mkdir -p ".claude/agents/deep-context"
  mkdir -p ".claude/agents/fix-bug"

  # Download templates
  start_spinner "Downloading templates..."

  # Helper: download only if file doesn't exist (for seed/user-customizable files)
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

  # Seed files: user-customizable content — only created if missing
  download_if_missing "${BASE_URL}/templates/CLAUDE.md" "CLAUDE.md"
  download_if_missing "${BASE_URL}/templates/.context/CONTEXT.md" ".context/CONTEXT.md"
  download_if_missing "${BASE_URL}/templates/.context/decisions/README.md" ".context/decisions/README.md"
  download_if_missing "${BASE_URL}/templates/.claude/skills/README.md" ".claude/skills/README.md"
  download_if_missing "${BASE_URL}/templates/.claude/skills/bug-reproduction/SKILL.md" ".claude/skills/bug-reproduction/SKILL.md"
  download_if_missing "${BASE_URL}/templates/.context/prp/templates/feature.md" ".context/prp/templates/feature.md"

  # Managed files: dotcontext commands — always downloaded (safe to overwrite)
  download "${BASE_URL}/templates/.claude/commands/setup-context.md" ".claude/commands/setup-context.md"
  download "${BASE_URL}/templates/.claude/commands/code-review.md" ".claude/commands/code-review.md"
  download "${BASE_URL}/templates/.claude/commands/generate-prp.md" ".claude/commands/generate-prp.md"
  download "${BASE_URL}/templates/.claude/commands/execute-prp.md" ".claude/commands/execute-prp.md"
  download "${BASE_URL}/templates/.claude/commands/add-decision.md" ".claude/commands/add-decision.md"
  download "${BASE_URL}/templates/.claude/commands/add-skill.md" ".claude/commands/add-skill.md"
  download "${BASE_URL}/templates/.claude/commands/add-command.md" ".claude/commands/add-command.md"
  download "${BASE_URL}/templates/.claude/commands/create-pr.md" ".claude/commands/create-pr.md"
  download "${BASE_URL}/templates/.claude/commands/pr-comment.md" ".claude/commands/pr-comment.md"
  download "${BASE_URL}/templates/.claude/commands/deep-context.md" ".claude/commands/deep-context.md"
  download "${BASE_URL}/templates/.claude/commands/fix-bug.md" ".claude/commands/fix-bug.md"
  download "${BASE_URL}/templates/.claude/commands/commit.md" ".claude/commands/commit.md"

  # StatusLine script
  download "${BASE_URL}/templates/.claude/scripts/statusline.sh" ".claude/scripts/statusline.sh"
  chmod +x ".claude/scripts/statusline.sh"

  # Agent definition files (always downloaded — managed by dotcontext)
  download "${BASE_URL}/templates/.claude/agents/code-review/compliance-checker.md" ".claude/agents/code-review/compliance-checker.md"
  download "${BASE_URL}/templates/.claude/agents/code-review/bug-detector.md" ".claude/agents/code-review/bug-detector.md"
  download "${BASE_URL}/templates/.claude/agents/code-review/security-analyst.md" ".claude/agents/code-review/security-analyst.md"
  download "${BASE_URL}/templates/.claude/agents/deep-context/step1-overview.md" ".claude/agents/deep-context/step1-overview.md"
  download "${BASE_URL}/templates/.claude/agents/deep-context/step2-subsystems.md" ".claude/agents/deep-context/step2-subsystems.md"
  download "${BASE_URL}/templates/.claude/agents/deep-context/step3-drill.md" ".claude/agents/deep-context/step3-drill.md"
  download "${BASE_URL}/templates/.claude/agents/deep-context/step4-dataflow.md" ".claude/agents/deep-context/step4-dataflow.md"
  download "${BASE_URL}/templates/.claude/agents/fix-bug/investigator.md" ".claude/agents/fix-bug/investigator.md"
  download "${BASE_URL}/templates/.claude/agents/fix-bug/fix-conservative.md" ".claude/agents/fix-bug/fix-conservative.md"
  download "${BASE_URL}/templates/.claude/agents/fix-bug/fix-minimal.md" ".claude/agents/fix-bug/fix-minimal.md"
  download "${BASE_URL}/templates/.claude/agents/fix-bug/fix-refactor.md" ".claude/agents/fix-bug/fix-refactor.md"
  download "${BASE_URL}/templates/.claude/agents/fix-bug/reviewer.md" ".claude/agents/fix-bug/reviewer.md"

  # Declarative cleanup: remove stale files from managed-only directories
  # NOTE: .claude/commands/ is excluded — users create custom commands there via /add-command
  cleanup_managed_dir ".claude/agents/code-review" \
    compliance-checker.md bug-detector.md security-analyst.md
  cleanup_managed_dir ".claude/agents/deep-context" \
    step1-overview.md step2-subsystems.md step3-drill.md step4-dataflow.md
  cleanup_managed_dir ".claude/agents/fix-bug" \
    investigator.md fix-conservative.md fix-minimal.md fix-refactor.md reviewer.md
  cleanup_managed_dir ".claude/scripts" \
    statusline.sh

  stop_spinner

  # Show skipped files after spinner (so output doesn't collide)
  if [ -n "$skipped_files" ]; then
    printf "$skipped_files" | while read -r f; do
      [ -n "$f" ] && print_gray "  skipped (exists): $f"
    done
  fi

  touch ".context/prp/generated/.keep"
  touch ".context/discoveries/.keep"
  touch ".context/bugs/.keep"

  # Setup notifications (optional, don't fail if it doesn't work)
  setup_notifications 2>/dev/null || true

  # MCP server configuration (only if .mcp.json doesn't exist)
  if [ ! -f ".mcp.json" ]; then
    local add_context7=false
    local add_atlassian=false

    if [ "$skip_prompts" = false ]; then
      echo ""
      print_blue "MCP Servers"
      print_gray "Configure Model Context Protocol servers for Claude Code"
      echo ""

      if confirm_yes "  Add Context7? (up-to-date library docs for LLMs)"; then
        add_context7=true
      fi

      if confirm_yes "  Add Atlassian? (Jira + Confluence via OAuth)"; then
        add_atlassian=true
      fi
    else
      # --yes flag: include both by default
      add_context7=true
      add_atlassian=true
    fi

    setup_mcp "$add_context7" "$add_atlassian"
  else
    print_gray "  skipped (exists): .mcp.json"
  fi

  # Substitute project name (only on fresh CLAUDE.md with placeholder)
  if grep -q "{{projectName}}" "CLAUDE.md" 2>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/{{projectName}}/$project_name/g" "CLAUDE.md"
    else
      sed -i "s/{{projectName}}/$project_name/g" "CLAUDE.md"
    fi
  fi

  echo ""
  if [ "$is_reinit" = true ]; then
    printf "  ${GREEN}${ICON_SUCCESS}${NC} Context structure updated\n"
  else
    printf "  ${GREEN}${ICON_SUCCESS}${NC} Context structure created\n"
  fi
  printf "  ${GRAY}CLAUDE.md  .context/  .claude/commands/ (12)  .claude/agents/ (12)${NC}\n"
  echo ""

  if [ "$skip_setup" = true ]; then
    printf "  ${CYAN}Next:${NC}  run ${CYAN}/setup-context${NC} in Claude Code\n"
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
