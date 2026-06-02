# ── Utilities ─────────────────────────────────────────────────────────────────

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

# Compare two semver strings (X.Y.Z). Returns 0 if $1 > $2, else 1.
version_gt() {
  [ "$1" = "$2" ] && return 1
  local IFS=.
  local a=($1) b=($2)
  local i ai bi
  for i in 0 1 2; do
    ai=${a[i]:-0}; bi=${b[i]:-0}
    # strip any pre-release suffix so "1.2.3-dev" compares as 3
    ai=${ai%%[^0-9]*}; bi=${bi%%[^0-9]*}
    if [ "${ai:-0}" -gt "${bi:-0}" ] 2>/dev/null; then return 0; fi
    if [ "${ai:-0}" -lt "${bi:-0}" ] 2>/dev/null; then return 1; fi
  done
  return 1
}

# Fetch the latest released version from GitHub, cached for 1 day.
# Echoes the bare version (no leading "v"); returns 1 on failure/offline.
fetch_latest_version() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotcontext"
  local cache_file="$cache_dir/latest_version"

  # Serve from cache if fresh (modified within the last day)
  if [ -f "$cache_file" ] && [ -n "$(find "$cache_file" -mtime -1 2>/dev/null)" ]; then
    cat "$cache_file"
    return 0
  fi

  local resp tag ver
  if command -v curl &> /dev/null; then
    resp=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null)
  elif command -v wget &> /dev/null; then
    resp=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null)
  else
    return 1
  fi

  tag=$(echo "$resp" | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
  ver=$(echo "$tag" | sed 's/^v//')
  [ -z "$ver" ] && return 1

  mkdir -p "$cache_dir" 2>/dev/null
  echo "$ver" > "$cache_file" 2>/dev/null
  echo "$ver"
}
