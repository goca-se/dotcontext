#!/usr/bin/env bash
# Spawns the local dotcontext binary in an isolated sandbox project.
#
# - HOME is sandboxed so global installs don't touch your real ~/.dotcontext
# - DOTCONTEXT_REPO_ROOT (CLI dev) points init/Layer-1 fetches at this repo
# - DOTCONTEXT_MARKETPLACE_ROOT (marketplace dev) points manifest + Layer 2
#   fetches at a local clone of goca-se/dotcontext-marketplace
#
# Usage (from the dotcontext repo root):
#   bash tests/sandbox.sh
#
# If a marketplace clone is found adjacent (../dotcontext-marketplace) it's
# used automatically. Otherwise the binary falls back to the GitHub URL,
# which is slower but more realistic.
#
# When you quit (q), the sandbox dir is deleted automatically.

set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$REPO/dotcontext"

if [ ! -x "$BIN" ]; then
  echo "ERROR: $BIN not found or not executable. Run 'make build' first." >&2
  exit 1
fi

# Auto-detect adjacent marketplace clone. User can override.
if [ -z "${DOTCONTEXT_MARKETPLACE_ROOT:-}" ] && [ -d "$REPO/../dotcontext-marketplace" ]; then
  export DOTCONTEXT_MARKETPLACE_ROOT="$(cd "$REPO/../dotcontext-marketplace" && pwd)"
fi

SBX="$(mktemp -d -t dotcontext-sandbox.XXXXXX)"
trap 'rm -rf "$SBX"' EXIT

mkdir -p "$SBX/proj/.context" "$SBX/home"
cd "$SBX/proj"

echo "Sandbox project: $SBX/proj"
echo "Sandbox home:    $SBX/home"
echo "Binary:          $BIN ($("$BIN" --version))"
if [ -n "${DOTCONTEXT_MARKETPLACE_ROOT:-}" ]; then
  echo "Marketplace:     $DOTCONTEXT_MARKETPLACE_ROOT (local clone)"
else
  echo "Marketplace:     ${MARKETPLACE_URL:-network — defaults to goca-se/dotcontext-marketplace}"
fi
echo "Press enter to launch the TUI..."
read -r _ || true

DOTCONTEXT_REPO_ROOT="$REPO" \
HOME="$SBX/home" \
  "$BIN"
