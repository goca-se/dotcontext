# ── UI Utilities ──────────────────────────────────────────────────────────────

get_term_width() {
  local width
  width=$(tput cols 2>/dev/null || echo "")
  if [ -z "$width" ] || [ "$width" -lt 40 ] 2>/dev/null; then
    width=80
  fi
  echo "$width"
}

# Print a section header with divider line
# Usage: print_block_header "Title"
print_block_header() {
  local title="$1"
  local width
  width=$(get_term_width)
  local title_len=${#title}
  local pad=$((width - title_len - 6))
  [ "$pad" -lt 4 ] && pad=4
  local line=""
  local i
  for ((i = 0; i < pad; i++)); do
    line="${line}─"
  done
  printf "\n  ${BOLD}── %s ${NC}${GRAY}%s${NC}\n" "$title" "$line"
}

# Print a block footer divider
print_block_footer() {
  local width
  width=$(get_term_width)
  local pad=$((width - 4))
  [ "$pad" -lt 10 ] && pad=10
  local line=""
  local i
  for ((i = 0; i < pad; i++)); do
    line="${line}─"
  done
  printf "  ${GRAY}%s${NC}\n" "$line"
}

# Print aligned label-value pair
# Usage: print_aligned "label" "value" [indent]
print_aligned() {
  local label="$1"
  local value="$2"
  local indent="${3:-4}"
  local pad_fmt="%-${indent}s"
  printf "  ${pad_fmt}${GRAY}%s${NC}\n" "$label" "$value"
}
