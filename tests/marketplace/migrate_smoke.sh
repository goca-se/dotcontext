#!/usr/bin/env bash
# Smoke test for src/lib/marketplace/migrate.sh.
#
# Setup: a sandbox project that already has Layer 2 files copied in (simulating
# a user upgraded from pre-v0.15). Run mp_migrate_run; verify lockfile entries
# are created with version=auto-registered.

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SANDBOX="$(mktemp -d -t dotcontext-migrate.XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

# Find adjacent marketplace clone, or error with instructions.
MARKETPLACE_ROOT="${DOTCONTEXT_MARKETPLACE_ROOT:-$REPO_ROOT/../dotcontext-marketplace}"
if [ ! -f "$MARKETPLACE_ROOT/manifest.json" ]; then
  echo "ERROR: marketplace clone not found at $MARKETPLACE_ROOT"
  echo "Either clone goca-se/dotcontext-marketplace adjacent to this repo, or"
  echo "set DOTCONTEXT_MARKETPLACE_ROOT to the clone path."
  exit 1
fi

. "$REPO_ROOT/src/header.sh"

export DOTCONTEXT_REPO_ROOT="$REPO_ROOT"
export DOTCONTEXT_MARKETPLACE_ROOT="$MARKETPLACE_ROOT"
export DOTCONTEXT_MANIFEST="$MARKETPLACE_ROOT/manifest.json"
export HOME="$SANDBOX/home"
mkdir -p "$HOME"

mkdir -p "$SANDBOX/proj/.context"
cd "$SANDBOX/proj"

# Pre-seed the project with code-review files (as if installed by old dotcontext).
# Templates now live in the marketplace repo.
mkdir -p .claude/commands .claude/agents/code-review
cp "$MARKETPLACE_ROOT/templates/.claude/commands/code-review.md" .claude/commands/code-review.md
cp "$MARKETPLACE_ROOT/templates/.claude/agents/code-review/compliance-checker.md" .claude/agents/code-review/
cp "$MARKETPLACE_ROOT/templates/.claude/agents/code-review/bug-detector.md" .claude/agents/code-review/
cp "$MARKETPLACE_ROOT/templates/.claude/agents/code-review/security-analyst.md" .claude/agents/code-review/

# Source libs
. "$REPO_ROOT/src/lib/ui/confirm.sh"
. "$REPO_ROOT/src/lib/marketplace/manifest.sh"
. "$REPO_ROOT/src/lib/marketplace/lockfile.sh"
. "$REPO_ROOT/src/lib/marketplace/scope.sh"
. "$REPO_ROOT/src/lib/marketplace/bundle.sh"
. "$REPO_ROOT/src/lib/marketplace/migrate.sh"

mp_manifest_load || { echo "FAIL: manifest load"; exit 1; }
echo "OK: manifest loaded"

# Should run the first time
if ! mp_migrate_should_run; then
  echo "FAIL: migrate_should_run returned false on fresh install"
  exit 1
fi
echo "OK: migrate_should_run is true initially"

# Run migration
mp_migrate_run >/tmp/migrate-output.txt 2>&1
cat /tmp/migrate-output.txt | grep -q "Detected" || {
  echo "FAIL: migration output missing 'Detected' line"
  cat /tmp/migrate-output.txt
  exit 1
}
echo "OK: migration emitted summary"

# Verify code-review is registered locally
mp_lock_has local code-review || { echo "FAIL: code-review not in local lockfile"; exit 1; }
echo "OK: code-review auto-registered"

# Verify version is "auto-registered"
v="$(mp_lock_get_field local code-review version)"
[ "$v" = "auto-registered" ] || { echo "FAIL: version is '$v' not 'auto-registered'"; exit 1; }
echo "OK: version field is auto-registered"

# Verify a NOT-pre-installed bundle (fix-bug) is NOT registered
mp_lock_has local fix-bug && { echo "FAIL: fix-bug should not be registered"; exit 1; } || true
echo "OK: fix-bug correctly not registered (files not present)"

# Idempotency: running migration again should be a no-op (marker present)
if mp_migrate_should_run; then
  echo "FAIL: marker not written"
  exit 1
fi
echo "OK: marker file written"

mp_migrate_run >/tmp/migrate-output2.txt 2>&1
# Second invocation still calls mp_migrate_run (we test the gate via mp_migrate_if_needed below)
echo "OK: re-run does not crash"

# Verify mp_migrate_if_needed correctly skips when marker exists
mp_migrate_if_needed >/tmp/migrate-skip.txt 2>&1
if grep -q "Detected" /tmp/migrate-skip.txt 2>/dev/null; then
  echo "FAIL: mp_migrate_if_needed ran when marker exists"
  exit 1
fi
echo "OK: mp_migrate_if_needed skipped (idempotent)"

echo ""
echo "All migrate smoke tests passed."
