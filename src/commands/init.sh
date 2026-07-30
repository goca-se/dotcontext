# ── Command: init ─────────────────────────────────────────────────────────────

cmd_init() {
  local project_name=""
  local skip_prompts=false
  local skip_setup=false
  local agents_flag=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name) project_name="$2"; shift 2 ;;
      -y|--yes) skip_prompts=true; shift ;;
      --no-setup) skip_setup=true; shift ;;
      --agents) agents_flag="$2"; shift 2 ;;
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

  # Resolve which harnesses to instantiate (sets SELECTED_AGENTS). Only the
  # chosen harnesses get files — no .claude/ for a Codex-only user, etc. (ADR-016)
  resolve_selected_agents "$agents_flag" "$skip_prompts"
  local selected="$SELECTED_AGENTS"
  if [ -z "$selected" ]; then
    print_red "No harness selected — nothing to set up. Re-run and pick at least one agent."
    return 1
  fi
  local wants_claude=false; agents_include "$selected" claude && wants_claude=true
  local wants_agents_skills=false
  local _id
  for _id in $selected; do [ "$_id" != "claude" ] && wants_agents_skills=true; done

  print_gray "Setting up for: $selected"

  # Harness-agnostic context skeleton (always)
  # specs/ + plans/ back the spec → plan → execute workflow (ADR-020).
  mkdir -p ".context/decisions" ".context/specs" ".context/plans" \
           ".context/discoveries" ".context/bugs"

  start_spinner "Downloading templates..."

  # Helper: download only if file doesn't exist (seed/user-customizable files)
  local skipped_files=""
  download_if_missing() {
    local url="$1"
    local target="$2"
    if [ -f "$target" ]; then
      [ "$is_reinit" = true ] && skipped_files="${skipped_files}${target}\n"
      return 0
    fi
    download "$url" "$target"
  }

  # ── Shared context (every harness) ──
  download_if_missing "${BASE_URL}/templates/.context/CONTEXT.md" ".context/CONTEXT.md"
  download_if_missing "${BASE_URL}/templates/.context/decisions/README.md" ".context/decisions/README.md"
  download_if_missing "${BASE_URL}/templates/.context/specs/README.md" ".context/specs/README.md"
  download_if_missing "${BASE_URL}/templates/.context/plans/README.md" ".context/plans/README.md"

  # ── Project instructions: canonical AGENTS.md + import stubs for selected agents ──
  for mapping in $(agent_instruction_seeds "$selected"); do
    # mappings are "url|target" ("|" can't appear in a URL or filename)
    download_if_missing "${mapping%|*}" "${mapping##*|}"
  done

  # ── Skills (shared SKILL.md content; physical home depends on selection) ──
  local skills_dir
  if [ "$wants_claude" = true ]; then skills_dir=".claude/skills"; else skills_dir=".agents/skills"; fi
  mkdir -p "$skills_dir/bug-reproduction" "$skills_dir/batch-operations" \
           "$skills_dir/git-platform" "$skills_dir/update-api-documentation"
  download_if_missing "${BASE_URL}/templates/.claude/skills/bug-reproduction/SKILL.md" "$skills_dir/bug-reproduction/SKILL.md"
  download_if_missing "${BASE_URL}/templates/.claude/skills/batch-operations/SKILL.md" "$skills_dir/batch-operations/SKILL.md"
  download_if_missing "${BASE_URL}/templates/.claude/skills/git-platform/SKILL.md" "$skills_dir/git-platform/SKILL.md"
  download_if_missing "${BASE_URL}/templates/.claude/skills/update-api-documentation/SKILL.md" "$skills_dir/update-api-documentation/SKILL.md"
  # If both Claude and an AGENTS.md-reading agent are selected, mirror so both see the skills
  if [ "$wants_claude" = true ] && [ "$wants_agents_skills" = true ]; then
    link_or_copy_dir ".claude/skills" ".agents/skills"
  fi

  # ── Claude-only toolkit (commands, agents, statusline, ignore) ──
  if [ "$wants_claude" = true ]; then
    mkdir -p ".claude/commands" ".claude/scripts" \
             ".claude/agents/code-review" ".claude/agents/deep-context" ".claude/agents/fix-bug" \
             ".claude/agents/spec-dc" ".claude/agents/plan-dc" ".claude/agents/execute-dc"
    download_if_missing "${BASE_URL}/templates/.claudeignore" ".claudeignore"

    local c
    for c in setup-context code-review spec-dc spec-quick plan-dc execute-dc add-decision add-skill \
             add-command create-pr pr-comment deep-context fix-bug commit; do
      download "${BASE_URL}/templates/.claude/commands/${c}.md" ".claude/commands/${c}.md"
    done

    download "${BASE_URL}/templates/.claude/scripts/statusline.sh" ".claude/scripts/statusline.sh"
    chmod +x ".claude/scripts/statusline.sh"

    local a
    for a in code-review/compliance-checker code-review/bug-detector code-review/security-analyst \
             deep-context/step1-overview deep-context/step2-subsystems deep-context/step3-drill \
             deep-context/step4-dataflow fix-bug/investigator fix-bug/fix-conservative \
             fix-bug/fix-minimal fix-bug/fix-refactor fix-bug/reviewer \
             spec-dc/reviewer-pro spec-dc/reviewer-fast \
             plan-dc/reviewer-pro plan-dc/reviewer-fast \
             execute-dc/reviewer-pro execute-dc/reviewer-fast; do
      download "${BASE_URL}/templates/.claude/agents/${a}.md" ".claude/agents/${a}.md"
    done

    cleanup_managed_dir ".claude/agents/code-review" \
      compliance-checker.md bug-detector.md security-analyst.md
    cleanup_managed_dir ".claude/agents/deep-context" \
      step1-overview.md step2-subsystems.md step3-drill.md step4-dataflow.md
    cleanup_managed_dir ".claude/agents/fix-bug" \
      investigator.md fix-conservative.md fix-minimal.md fix-refactor.md reviewer.md
    cleanup_managed_dir ".claude/agents/spec-dc" \
      reviewer-pro.md reviewer-fast.md
    cleanup_managed_dir ".claude/agents/plan-dc" \
      reviewer-pro.md reviewer-fast.md
    cleanup_managed_dir ".claude/agents/execute-dc" \
      reviewer-pro.md reviewer-fast.md
    cleanup_managed_dir ".claude/scripts" \
      statusline.sh notify.sh tool-failure-guard.sh
  fi

  stop_spinner

  if [ -n "$skipped_files" ]; then
    printf "$skipped_files" | while read -r f; do
      [ -n "$f" ] && print_gray "  skipped (exists): $f"
    done
  fi

  touch ".context/discoveries/.keep" ".context/bugs/.keep"

  # ── Commands per selected harness (opencode/Copilot native; others via AGENTS.md Workflows) ──
  emit_agent_commands "$selected" 2>/dev/null || true

  # ── Hooks per selected harness (notifications; Claude also gets the failure guard) ──
  setup_agent_hooks "$selected" 2>/dev/null || true

  # ── MCP servers (cross-agent; Context7/Atlassian work across harnesses) ──
  if [ ! -f ".mcp.json" ]; then
    local add_context7=false
    local add_atlassian=false
    if [ "$skip_prompts" = false ]; then
      echo ""
      print_blue "MCP Servers"
      print_gray "Configure Model Context Protocol servers for your agents"
      echo ""
      confirm_yes "  Add Context7? (up-to-date library docs for LLMs)" && add_context7=true
      confirm_yes "  Add Atlassian? (Jira + Confluence via OAuth)" && add_atlassian=true
    else
      add_context7=true
      add_atlassian=true
    fi
    setup_mcp "$add_context7" "$add_atlassian"
  else
    print_gray "  skipped (exists): .mcp.json"
  fi

  # Offer to install shell tab-completion (interactive runs only)
  if [ "$skip_prompts" = false ] && [ -t 0 ]; then
    offer_completion_install
  fi

  # Substitute project name in any instruction file that still has the placeholder
  local inst_file
  for inst_file in AGENTS.md CLAUDE.md GEMINI.md; do
    if grep -q "{{projectName}}" "$inst_file" 2>/dev/null; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/{{projectName}}/$project_name/g" "$inst_file"
      else
        sed -i "s/{{projectName}}/$project_name/g" "$inst_file"
      fi
    fi
  done

  echo ""
  if [ "$is_reinit" = true ]; then
    printf "  ${GREEN}${ICON_SUCCESS}${NC} Context structure updated\n"
  else
    printf "  ${GREEN}${ICON_SUCCESS}${NC} Context structure created\n"
  fi
  local _names="" _i
  for _i in $selected; do _names="$_names$(agent_name "$_i"), "; done
  printf "  ${GRAY}Harnesses: %s${NC}\n" "${_names%, }"
  echo ""

  # /setup-context is a Claude command — only when Claude is part of the setup
  if [ "$wants_claude" = true ]; then
    if [ "$skip_setup" = true ]; then
      printf "  ${CYAN}Next:${NC}  run ${CYAN}/setup-context${NC} in Claude Code\n"
    elif command -v claude &> /dev/null; then
      printf "  ${CYAN}Running /setup-context...${NC}\n\n"
      claude "/setup-context"
    else
      printf "  ${YELLOW}Claude CLI not found.${NC} Run ${CYAN}/setup-context${NC} manually in Claude Code.\n"
    fi
  else
    printf "  ${CYAN}Next:${NC}  edit ${CYAN}AGENTS.md${NC} and ${CYAN}.context/CONTEXT.md${NC} to describe your project\n"
  fi
  echo ""
}
