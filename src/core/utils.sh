# ── Utilities ─────────────────────────────────────────────────────────────────

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

prompt() {
  local message="$1"
  local default="$2"
  local result
  if [ -n "$default" ]; then
    printf "%s [%s]: " "$message" "$default" >&2
    read -r result
    echo "${result:-$default}"
  else
    printf "%s: " "$message" >&2
    read -r result
    echo "$result"
  fi
}

confirm() {
  local message="$1"
  local answer
  printf "%s [y/N]: " "$message"
  read -r answer
  [[ "$answer" =~ ^[Yy] ]]
}

confirm_yes() {
  local message="$1"
  local answer
  printf "%s [Y/n]: " "$message"
  read -r answer
  [[ ! "$answer" =~ ^[Nn] ]]
}

download() {
  local url="$1"
  local target="$2"
  if command -v curl &> /dev/null; then
    curl -fsSL "$url" -o "$target"
  elif command -v wget &> /dev/null; then
    wget -q "$url" -O "$target"
  else
    print_red "Error: curl or wget required"
    exit 1
  fi
}

# Declarative cleanup: remove files in a managed directory that aren't in the expected list.
# Usage: cleanup_managed_dir <dir> <expected_file1> [expected_file2] ...
cleanup_managed_dir() {
  local dir="$1"; shift
  local expected=("$@")

  [ -d "$dir" ] || return 0
  [ ${#expected[@]} -eq 0 ] && return 0

  for file in "$dir"/*; do
    [ -L "$file" ] && continue
    [ -f "$file" ] || continue
    local name=$(basename "$file")
    local keep=false
    for expected_name in "${expected[@]}"; do
      if [ "$name" = "$expected_name" ]; then
        keep=true
        break
      fi
    done
    if [ "$keep" = false ]; then
      rm -f "$file"
    fi
  done
}
