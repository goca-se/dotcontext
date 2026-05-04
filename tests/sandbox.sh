#!/usr/bin/env bash
# Spawns the local dotcontext binary in an isolated sandbox project.
# - HOME is sandboxed so global installs don't touch your real ~/.dotcontext
# - DOTCONTEXT_REPO_ROOT points install handlers at local files (no GitHub)
# - DOTCONTEXT_MANIFEST points at the local manifest.json
#
# Usage (from the dotcontext repo root):
#   bash tests/sandbox.sh
#
# When you quit (q), the sandbox dir is deleted automatically.

set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$REPO/dotcontext"
MANIFEST="$REPO/marketplace/manifest.json"

if [ ! -x "$BIN" ]; then
  echo "ERROR: $BIN not found or not executable. Run 'make build' first." >&2
  exit 1
fi

SBX="$(mktemp -d -t dotcontext-sandbox.XXXXXX)"
trap 'rm -rf "$SBX"' EXIT

mkdir -p "$SBX/proj/.context" "$SBX/home"
cd "$SBX/proj"

echo "Sandbox project: $SBX/proj"
echo "Sandbox home:    $SBX/home"
echo "Binary:          $BIN ($("$BIN" --version))"
echo "Press enter to launch the TUI..."
read -r _ || true

DOTCONTEXT_REPO_ROOT="$REPO" \
DOTCONTEXT_MANIFEST="$MANIFEST" \
HOME="$SBX/home" \
  "$BIN"
