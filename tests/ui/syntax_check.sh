#!/usr/bin/env bash
# Quick syntax check for src/lib/. Run by Makefile in CI-style environments.
set -eu
HERE="$(cd "$(dirname "$0")/../.." && pwd)"

fails=0
for f in "$HERE"/src/lib/ui/*.sh "$HERE"/src/lib/marketplace/*.sh "$HERE"/src/lib/install/*.sh; do
  [ -f "$f" ] || continue
  if bash -n "$f"; then
    printf '  OK   %s\n' "${f#$HERE/}"
  else
    printf '  FAIL %s\n' "${f#$HERE/}" >&2
    fails=$(( fails + 1 ))
  fi
done

if [ "$fails" -gt 0 ]; then
  printf '%d file(s) failed syntax check.\n' "$fails" >&2
  exit 1
fi
printf 'src/lib syntax OK\n'
