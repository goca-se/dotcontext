# ── Command: help ─────────────────────────────────────────────────────────────

cmd_help() {
  local width
  width=$(get_term_width)

  local cmd_col=20
  local opt_col=22
  if [ "$width" -ge 100 ]; then
    cmd_col=24
    opt_col=26
  fi

  echo ""
  printf "  ${BOLD}dotcontext${NC} ${GRAY}— AI context toolkit for Claude Code${NC}\n"
  echo ""

  printf "  ${BLUE}${BOLD}Usage${NC}\n"
  printf "    dotcontext [command] [options]\n"
  printf "    dotcontext                       ${GRAY}# opens marketplace TUI${NC}\n"
  echo ""

  printf "  ${BLUE}${BOLD}Commands${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" ""           "Open marketplace TUI (no-args)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "init"       "Create Layer 1 + open Claude Code with /setup-context"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "update"     "Update CLI / Layer 1 templates / lockfile-tracked items"
  echo ""

  printf "  ${BLUE}${BOLD}Init Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--name, -n <name>" "Project name"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--yes, -y"         "Skip prompts, use defaults"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--no-setup"        "Skip automatic /setup-context"
  echo ""

  printf "  ${BLUE}${BOLD}Update Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--cli"       "Only update CLI"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--templates" "Only update templates"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--yes, -y"   "Update without asking"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--dry-run"   "Show what would change"
  echo ""

  printf "  ${BLUE}${BOLD}Global Options${NC}\n"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--help, -h"    "Show this help"
  printf "    ${YELLOW}%-${opt_col}s${NC}%s\n" "--version, -v" "Show version"
  echo ""

  printf "  ${BLUE}${BOLD}Marketplace TUI${NC} ${GRAY}(when running with no args)${NC}\n"
  printf "    ${GRAY}Three tabs: Browse · Installed · Status${NC}\n"
  printf "    ${GRAY}↑↓ navigate · space toggle · g/l scope · p starter pack · i install${NC}\n"
  printf "    ${GRAY}tab cycles tabs · q quits${NC}\n"
  echo ""

  printf "  ${BLUE}${BOLD}Claude Code Commands${NC} ${GRAY}(after init)${NC}\n"
  printf "    ${GRAY}Layer 1 — installed by 'init':${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/setup-context"  "Analyze codebase, populate context"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/commit"         "Smart commit messages"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/deep-context"   "Structured codebase exploration"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/add-decision"   "Add architectural decision (ADR)"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/add-skill"      "Add skill guide"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/add-command"    "Create custom command"
  printf "    ${GRAY}Layer 2 — install via marketplace TUI:${NC}\n"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/generate-prp"   "Plan a feature with a PRP"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/execute-prp"    "Implement a planned PRP"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/code-review"    "Multi-agent review"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/fix-bug"        "Test-driven bug fixing"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/create-pr"      "Create PR / MR"
  printf "    ${CYAN}%-${cmd_col}s${NC}%s\n" "/pr-comment"     "Comment on PR / MR"
  echo ""

  printf "  ${BLUE}${BOLD}Examples${NC}\n"
  printf "    ${GRAY}\$${NC} dotcontext init\n"
  printf "    ${GRAY}\$${NC} dotcontext init --name \"My Project\"\n"
  printf "    ${GRAY}\$${NC} dotcontext                       ${GRAY}# open TUI${NC}\n"
  printf "    ${GRAY}\$${NC} dotcontext update --dry-run\n"
  echo ""
}
