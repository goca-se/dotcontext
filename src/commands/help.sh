# ── Command: help ─────────────────────────────────────────────────────────────

cmd_help() {
  local width
  width=$(get_term_width)

  # Determine column widths based on terminal
  local cmd_col=20
  local opt_col=22
  if [ "$width" -ge 100 ]; then
    cmd_col=24
    opt_col=26
  fi

  echo ""
  printf "  ${BOLD}dotcontext${NC} ${GRAY}— AI context toolkit for coding agents${NC}\n"
  echo ""

  # Usage
  printf "  ${BLUE}${BOLD}Usage${NC}\n"
  printf "    dotcontext <command> [options]\n"
  echo ""

  # Commands
  printf "  ${BLUE}${BOLD}Commands${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "init"       "Initialize context for your agent(s)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "update"     "Update CLI and/or templates"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "doctor"     "Check project setup health"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "completion" "Generate shell tab completions"
  echo ""

  # Init Options
  printf "  ${BLUE}${BOLD}Init Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--name, -n <name>" "Project name"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--agents <list>"   "Harnesses to set up (e.g. claude,codex). Default: detected"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--yes, -y"         "Skip prompts, use defaults"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--no-setup"        "Skip automatic /setup-context"
  echo ""

  # Update Options
  printf "  ${BLUE}${BOLD}Update Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--cli"       "Only update CLI"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--templates" "Only update templates"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--yes, -y"   "Update without asking"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--dry-run"   "Show what would change"
  echo ""

  # Global Options
  printf "  ${BLUE}${BOLD}Global Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--help, -h"        "Show this help"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--version, -v"     "Show version (add --features or --json)"
  echo ""

  # Claude Code Commands
  printf "  ${BLUE}${BOLD}Workflows${NC} ${GRAY}(after init — slash commands on Claude/opencode/Copilot; AGENTS.md elsewhere)${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/setup-context"  "Analyze codebase and populate context"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/spec-dc"        "Write a behavior spec (the WHAT)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/spec-quick"     "Same spec, fast path (one review pass)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/plan-dc"        "Turn a spec into a plan (the HOW)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/execute-dc"     "Implement a plan in waves (the DO)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/code-review"    "Multi-agent code review"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/commit"         "Smart commit messages"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/create-pr"      "Create PR with description"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/deep-context"   "Structured codebase exploration"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/fix-bug"        "Test-driven bug fixing"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/add-decision"   "Add architectural decision"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/add-skill"      "Add skill guide"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/add-command"    "Create custom command"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/release"        "Version bump and release"
  echo ""

  # Examples
  printf "  ${BLUE}${BOLD}Examples${NC}\n"
  printf "    ${GRAY}\$${NC} dotcontext init\n"
  printf "    ${GRAY}\$${NC} dotcontext init --name \"My Project\"\n"
  printf "    ${GRAY}\$${NC} dotcontext update --dry-run\n"
  printf "    ${GRAY}\$${NC} dotcontext doctor\n"
  printf "    ${GRAY}\$${NC} eval \"\$(dotcontext completion bash)\"\n"
  echo ""
}

# ── Command: version ──────────────────────────────────────────────────────────
# Plain `--version` prints the version. `--features` adds a human-readable
# capability list; `--json` emits a machine-readable capability handshake so an
# agent/harness can discover what this dotcontext supports before invoking it.

cmd_version() {
  local features=false
  local json=false
  for arg in "$@"; do
    case "$arg" in
      --features) features=true ;;
      --json) json=true ;;
      *)
        printf "${RED}Unknown option for --version: %s${NC}\n" "$arg" >&2
        printf "Usage: dotcontext --version [--features] [--json]\n" >&2
        return 1
        ;;
    esac
  done

  # Build the supported-agents array from the adapter registry (ADR-016)
  local id agents_json="" agents_list=""
  for id in $AGENT_IDS; do
    agents_json="${agents_json}\"$id\", "
    agents_list="${agents_list}$id "
  done
  agents_json="[${agents_json%, }]"
  agents_list="${agents_list% }"

  if [ "$json" = true ]; then
    cat <<JSON
{
  "name": "dotcontext",
  "version": "$VERSION",
  "repo": "$REPO",
  "commands": ["init", "update", "doctor", "completion"],
  "capabilities": {
    "update_check": true,
    "askuserquestion": true,
    "statusline": true,
    "hooks": true,
    "skills": true,
    "commands": true,
    "multiagent": true,
    "agents": $agents_json
  }
}
JSON
    return 0
  fi

  echo "dotcontext $VERSION"
  if [ "$features" = true ]; then
    echo ""
    echo "Capabilities:"
    printf "  %-16s %s\n" "update_check"    "yes"
    printf "  %-16s %s\n" "askuserquestion" "yes"
    printf "  %-16s %s\n" "statusline"      "yes"
    printf "  %-16s %s\n" "hooks"           "yes"
    printf "  %-16s %s\n" "skills"          "yes"
    printf "  %-16s %s\n" "commands"        "yes"
    printf "  %-16s %s\n" "multiagent"      "yes"
    printf "  %-16s %s\n" "agents"          "$agents_list"
  fi
}
