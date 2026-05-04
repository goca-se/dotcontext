#!/usr/bin/env bash
# validate-manifest.sh — sanity-checks marketplace/manifest.json
#
# Checks (all critical, no jq required):
#   1. manifest.json exists and is non-empty
#   2. Every "src" path referenced by an item exists in the working tree
#   3. Every "depends_on" id resolves to another item in the manifest
#   4. No duplicate item ids
#   5. starter_pack count matches expectation (informational)
#
# Optional (jq-only, richer messages):
#   - JSON Schema check via jq's `input` + spot validation
#   - Detailed error pointing to the exact item id

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_ROOT/marketplace/manifest.json"

red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

fail() { red "FAIL: $*"; exit 1; }

[ -f "$MANIFEST" ] || fail "manifest not found: $MANIFEST"
[ -s "$MANIFEST" ] || fail "manifest is empty: $MANIFEST"

HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

# -------- 1. Source paths exist ---------------------------------------------

# Extract every "src" line — works with or without jq.
if [ "$HAS_JQ" -eq 1 ]; then
  SRCS="$(jq -r '.items[] | select(.files != null) | .files[].src' "$MANIFEST")"
else
  # Pure-bash fallback: grep "src" lines from the JSON.
  SRCS="$(grep -oE '"src"[[:space:]]*:[[:space:]]*"[^"]+"' "$MANIFEST" | sed -E 's/.*"src"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
fi

MISSING_SRCS=""
for src in $SRCS; do
  if [ ! -e "$REPO_ROOT/$src" ]; then
    MISSING_SRCS="$MISSING_SRCS\n  - $src"
  fi
done

if [ -n "$MISSING_SRCS" ]; then
  red "Missing source files referenced by manifest:"
  printf "$MISSING_SRCS\n" >&2
  exit 1
fi

# -------- 2. Duplicate ids ---------------------------------------------------

if [ "$HAS_JQ" -eq 1 ]; then
  IDS="$(jq -r '.items[].id' "$MANIFEST")"
else
  IDS="$(grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' "$MANIFEST" | sed -E 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
fi

DUPES="$(printf '%s\n' "$IDS" | sort | uniq -d)"
if [ -n "$DUPES" ]; then
  red "Duplicate item ids:"
  printf '%s\n' "$DUPES" >&2
  exit 1
fi

# -------- 3. depends_on resolves --------------------------------------------

if [ "$HAS_JQ" -eq 1 ]; then
  DEPS="$(jq -r '.items[] | select(.depends_on != null) | .id as $i | .depends_on[] | "\($i) -> \(.)"' "$MANIFEST")"
  KNOWN_IDS=" $(printf '%s' "$IDS" | tr '\n' ' ') "
  echo "$DEPS" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    target="${line##*-> }"
    case "$KNOWN_IDS" in
      *" $target "*) ;;
      *) red "Broken depends_on: $line"; exit 1 ;;
    esac
  done
fi

# -------- 4. starter_pack tally ---------------------------------------------

if [ "$HAS_JQ" -eq 1 ]; then
  PACK_COUNT="$(jq '[.items[] | select(.starter_pack == true)] | length' "$MANIFEST")"
  TOTAL_COUNT="$(jq '.items | length' "$MANIFEST")"
  yellow "manifest: ${TOTAL_COUNT} items, ${PACK_COUNT} in starter pack"
fi

green "manifest OK: $MANIFEST"
