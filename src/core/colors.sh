# ── Colors ────────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  GRAY='\033[0;90m'
  BOLD='\033[1m'
  DIM='\033[2m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' GRAY='' BOLD='' DIM='' NC=''
fi

# Helper print functions
print_green() { printf "${GREEN}%s${NC}\n" "$1"; }
print_red() { printf "${RED}%s${NC}\n" "$1"; }
print_yellow() { printf "${YELLOW}%s${NC}\n" "$1"; }
print_blue() { printf "${BLUE}%s${NC}\n" "$1"; }
print_gray() { printf "${GRAY}%s${NC}\n" "$1"; }
print_cyan() { printf "${CYAN}%s${NC}\n" "$1"; }
