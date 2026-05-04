# ── lib/install/cli.sh ────────────────────────────────────────────────────────
#
# External CLI install/remove via OS package manager.
#
# Public API:
#   mp_install_cli <id>      # scope is implicitly machine
#   mp_remove_cli  <id>
#   mp_cli_status  <id>      # echoes "ok", "missing", "unauthenticated", "unknown"
#
# OS detection key matches manifest package_managers keys:
#   darwin, linux:debian, linux:redhat, linux:arch, windows

mp_detect_os_key() {
  case "$(uname -s)" in
    Darwin) echo "darwin"; return 0 ;;
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID_LIKE:-${ID:-}}" in
          *debian*|*ubuntu*) echo "linux:debian"; return 0 ;;
          *rhel*|*fedora*|*centos*) echo "linux:redhat"; return 0 ;;
          *arch*) echo "linux:arch"; return 0 ;;
        esac
        # Fallback by ID alone.
        case "${ID:-}" in
          debian|ubuntu|pop) echo "linux:debian"; return 0 ;;
          fedora|rhel|centos|rocky|alma) echo "linux:redhat"; return 0 ;;
          arch|manjaro|endeavouros) echo "linux:arch"; return 0 ;;
        esac
      fi
      echo "linux:debian"; return 0  # best-guess default
      ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows"; return 0 ;;
    *) echo "unknown"; return 1 ;;
  esac
}

mp_pick_pm() {
  local id="$1"
  local os_key pm_json pm_name pm_pkg
  os_key="$(mp_detect_os_key)"
  pm_json="$(mp_manifest_pm_for_os "$id" "$os_key")"
  if [ "$pm_json" = "{}" ] || [ -z "$pm_json" ]; then
    printf '' >&2
    echo ""
    return 1
  fi
  # Pick the first pm we can find on PATH. Order: brew, apt, dnf, pacman, winget.
  for pm_name in brew apt dnf pacman winget; do
    pm_pkg="$(printf '%s' "$pm_json" | jq -r --arg n "$pm_name" '.[$n] // ""')"
    if [ -n "$pm_pkg" ] && command -v "$pm_name" >/dev/null 2>&1; then
      printf '%s\t%s\n' "$pm_name" "$pm_pkg"
      return 0
    fi
  done
  return 1
}

mp_install_cli() {
  local id="$1"
  local pick pm pkg verify
  pick="$(mp_pick_pm "$id")" || {
    local os_key listed
    os_key="$(mp_detect_os_key)"
    listed="$(printf '%s' "$MP_MANIFEST_JSON" | jq -r --arg id "$id" --arg os "$os_key" \
      '.items[] | select(.id == $id) | .package_managers[$os] // {} | to_entries[] | select(.key != "repo") | "\(.key) \(.value)"')"
    printf 'No supported package manager found for %s on this OS (%s).\n' "$id" "$os_key" >&2
    if [ -n "$listed" ]; then
      printf 'Manifest lists these for your platform — install one of them, then re-run:\n' >&2
      printf '%s\n' "$listed" | while IFS= read -r line; do printf '  - %s\n' "$line" >&2; done
    else
      printf 'No package manager configured for %s on %s in the manifest.\n' "$id" "$os_key" >&2
    fi
    return 1
  }
  pm="${pick%%	*}"
  pkg="${pick##*	}"

  printf 'About to install %s via %s install %s\n' "$id" "$pm" "$pkg"
  if ! ui_confirm "Proceed?" default-yes; then
    printf 'Skipped.\n'
    return 1
  fi

  case "$pm" in
    brew)   brew install "$pkg" || return 1 ;;
    apt)    sudo apt-get update && sudo apt-get install -y "$pkg" || return 1 ;;
    dnf)    sudo dnf install -y "$pkg" || return 1 ;;
    pacman) sudo pacman -S --noconfirm "$pkg" || return 1 ;;
    winget) winget install --silent "$pkg" || return 1 ;;
    *)      printf 'unknown package manager %s\n' "$pm" >&2; return 1 ;;
  esac

  verify="$(mp_manifest_verify_command "$id")"
  if [ -n "$verify" ]; then
    if ! eval "$verify" >/dev/null 2>&1; then
      printf 'Install completed but %s failed. Check installation manually.\n' "$verify" >&2
      return 1
    fi
  fi

  local version
  version="$(mp_manifest_field "$id" version)"
  mp_lock_add_cli "$id" "$version" "$pm"
}

mp_remove_cli() {
  local id="$1"
  local pm
  pm="$(mp_lock_get_field machine "$id" package_manager_used)"
  if [ -z "$pm" ]; then
    printf 'No record of %s in machine lockfile; nothing to remove.\n' "$id" >&2
    return 0
  fi
  printf 'About to remove %s (installed via %s).\n' "$id" "$pm"
  printf 'This is a system-wide change. Are you sure?\n'
  if ! ui_confirm "Confirm uninstall?"; then
    return 1
  fi
  if ! ui_confirm "Really sure?"; then
    return 1
  fi

  # Pick the package name from manifest for this PM.
  local os_key pm_json pkg
  os_key="$(mp_detect_os_key)"
  pm_json="$(mp_manifest_pm_for_os "$id" "$os_key")"
  pkg="$(printf '%s' "$pm_json" | jq -r --arg n "$pm" '.[$n] // ""')"
  [ -z "$pkg" ] && pkg="$id"  # best-effort fallback

  case "$pm" in
    brew)   brew uninstall "$pkg" || true ;;
    apt)    sudo apt-get remove -y "$pkg" || true ;;
    dnf)    sudo dnf remove -y "$pkg" || true ;;
    pacman) sudo pacman -R --noconfirm "$pkg" || true ;;
    winget) winget uninstall --silent "$pkg" || true ;;
  esac
  mp_lock_remove machine "$id"
}

# Status check for the Status tab.
mp_cli_status() {
  local id="$1" verify auth
  verify="$(mp_manifest_verify_command "$id")"
  auth="$(mp_manifest_auth_command "$id")"
  if [ -n "$verify" ] && ! eval "$verify" >/dev/null 2>&1; then
    echo "missing"; return 0
  fi
  if [ -n "$auth" ] && ! eval "$auth" >/dev/null 2>&1; then
    echo "unauthenticated"; return 0
  fi
  echo "ok"
}
