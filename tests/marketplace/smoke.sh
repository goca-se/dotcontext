#!/usr/bin/env bash
# Smoke test for src/lib/marketplace + src/lib/install.
#
# Creates a sandbox project under TMPDIR, installs a few items, removes them,
# and verifies lockfile + filesystem stay in sync.

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SANDBOX="$(mktemp -d -t dotcontext-smoke.XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

# Find adjacent marketplace clone, or error with instructions.
MARKETPLACE_ROOT="${DOTCONTEXT_MARKETPLACE_ROOT:-$REPO_ROOT/../dotcontext-marketplace}"
if [ ! -f "$MARKETPLACE_ROOT/manifest.json" ]; then
  echo "ERROR: marketplace clone not found at $MARKETPLACE_ROOT"
  echo "Either clone goca-se/dotcontext-marketplace adjacent to this repo, or"
  echo "set DOTCONTEXT_MARKETPLACE_ROOT to the clone path."
  exit 1
fi

# Need to load header constants for MARKETPLACE_URL etc.
. "$REPO_ROOT/src/header.sh"

export DOTCONTEXT_REPO_ROOT="$REPO_ROOT"
export DOTCONTEXT_MARKETPLACE_ROOT="$MARKETPLACE_ROOT"
export DOTCONTEXT_MANIFEST="$MARKETPLACE_ROOT/manifest.json"
export HOME="$SANDBOX/home"
mkdir -p "$HOME"

mkdir -p "$SANDBOX/proj/.context"
cd "$SANDBOX/proj"

# Source library files (matching the bundle order in Makefile).
. "$REPO_ROOT/src/lib/ui/confirm.sh"
. "$REPO_ROOT/src/lib/marketplace/manifest.sh"
. "$REPO_ROOT/src/lib/marketplace/lockfile.sh"
. "$REPO_ROOT/src/lib/marketplace/scope.sh"
. "$REPO_ROOT/src/lib/marketplace/bundle.sh"
. "$REPO_ROOT/src/lib/install/command.sh"
. "$REPO_ROOT/src/lib/install/skill.sh"
. "$REPO_ROOT/src/lib/install/script.sh"
. "$REPO_ROOT/src/lib/install/mcp.sh"
. "$REPO_ROOT/src/lib/install/hook.sh"
. "$REPO_ROOT/src/lib/install/cli.sh"
. "$REPO_ROOT/src/lib/install/dispatch.sh"

mp_manifest_load || { echo "FAIL: manifest load"; exit 1; }

# Sanity: ids exist
ids="$(mp_manifest_ids)"
if [ -z "$ids" ]; then echo "FAIL: no ids"; exit 1; fi
echo "OK: manifest loaded with $(echo "$ids" | wc -l | tr -d ' ') items"

# Sanity: starter pack (16 items per ADR-015 v3 — methodology helpers + dream team + MCPs + CLIs)
sp="$(mp_manifest_starter_pack_ids | wc -l | tr -d ' ')"
if [ "$sp" != "16" ]; then echo "FAIL: expected 16 starter pack items, got $sp"; exit 1; fi
echo "OK: starter pack has $sp items"

# Bundle resolution: code-review should yield 4 files
files="$(mp_bundle_resolve_files code-review | grep -c '	' || true)"
if [ "$files" != "4" ]; then echo "FAIL: code-review expected 4 files, got $files"; exit 1; fi
echo "OK: code-review bundle resolves to 4 files"

# Bundle with depends_on: fix-bug should pull in bug-reproduction-skill
bundle_ids="$(mp_bundle_resolve_ids fix-bug | tr -d '\n' | wc -c)"
echo "$(mp_bundle_resolve_ids fix-bug)" | grep -q bug-reproduction-skill || {
  echo "FAIL: fix-bug bundle did not include bug-reproduction-skill"; exit 1; }
echo "OK: fix-bug bundle pulls in bug-reproduction-skill"

# Install code-review (local). Uses DOTCONTEXT_REPO_ROOT to avoid network.
mp_install code-review local || { echo "FAIL: install code-review"; exit 1; }
[ -f .claude/commands/code-review.md ] || { echo "FAIL: command file not copied"; exit 1; }
[ -f .claude/agents/code-review/compliance-checker.md ] || { echo "FAIL: agent not copied"; exit 1; }
mp_lock_has local code-review || { echo "FAIL: lockfile entry missing"; exit 1; }
echo "OK: code-review installed; lockfile + files in sync"

# Idempotency: install twice — should not error or duplicate
mp_install code-review local || { echo "FAIL: 2nd install failed"; exit 1; }
count="$(jq '.items | length' .context/.dotcontext-state.json)"
if [ "$count" != "1" ]; then echo "FAIL: lockfile has $count entries, expected 1"; exit 1; fi
echo "OK: install is idempotent"

# Remove
mp_remove code-review local || { echo "FAIL: remove"; exit 1; }
[ ! -f .claude/commands/code-review.md ] || { echo "FAIL: command file not removed"; exit 1; }
[ ! -d .claude/agents/code-review ] || { echo "FAIL: agent dir not removed"; exit 1; }
mp_lock_has local code-review && { echo "FAIL: lockfile entry not removed"; exit 1; } || true
echo "OK: code-review removed; lockfile + files in sync"

# Install with depends_on: fix-bug
mp_install fix-bug local || { echo "FAIL: install fix-bug"; exit 1; }
[ -f .claude/skills/bug-reproduction/SKILL.md ] || { echo "FAIL: dep skill not installed"; exit 1; }
mp_lock_has local fix-bug || { echo "FAIL: fix-bug not in lockfile"; exit 1; }
echo "OK: fix-bug installed with transitive dep file"

# MCP install (global) — writes to $HOME/.claude/settings.json
mp_install atlassian-mcp global || { echo "FAIL: install atlassian-mcp"; exit 1; }
grep -q '"atlassian"' "$HOME/.claude/settings.json" || { echo "FAIL: atlassian-mcp not in settings"; exit 1; }
mp_lock_has global atlassian-mcp || { echo "FAIL: atlassian-mcp not in lockfile"; exit 1; }
echo "OK: atlassian-mcp installed globally"

# MCP remove
mp_remove atlassian-mcp global || { echo "FAIL: remove atlassian-mcp"; exit 1; }
grep -q '"atlassian"' "$HOME/.claude/settings.json" && { echo "FAIL: atlassian still in settings"; exit 1; } || true
echo "OK: atlassian-mcp removed cleanly"

echo ""
echo "All smoke tests passed."
