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
  printf "  ${BOLD}dotcontext${NC} ${GRAY}— AI context toolkit for Claude Code${NC}\n"
  echo ""

  # Usage
  printf "  ${BLUE}${BOLD}Usage${NC}\n"
  printf "    dotcontext <command> [options]\n"
  echo ""

  # Commands
  printf "  ${BLUE}${BOLD}Commands${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "init"       "Initialize .context structure + open Claude Code"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "update"     "Update CLI and/or templates"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "doctor"     "Check project setup health"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "completion" "Generate shell tab completions"
  echo ""

  # Init Options
  printf "  ${BLUE}${BOLD}Init Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--name, -n <name>" "Project name"
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
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--help, -h"    "Show this help"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--version, -v" "Show version"
  echo ""

  # Claude Code Commands
  printf "  ${BLUE}${BOLD}Claude Code Commands${NC} ${GRAY}(after init)${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/setup-context"  "Analyze codebase and populate context"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/generate-prp"   "Plan a new feature"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/execute-prp"    "Implement a planned feature"
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
