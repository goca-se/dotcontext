# ── Spinner ───────────────────────────────────────────────────────────────────

SPINNER_PID=""
start_spinner() {
  local msg="$1"
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local i=0
  while true; do
    printf "\r  ${BLUE}${frames[$i]}${NC} ${msg}"
    i=$(( (i + 1) % 10 ))
    sleep 0.1
  done &
  SPINNER_PID=$!
}

stop_spinner() {
  local msg="$1"
  if [ -n "$SPINNER_PID" ]; then
    kill "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
  fi
  printf "\r\033[K"
  if [ -n "$msg" ]; then
    echo "$msg"
  fi
}
