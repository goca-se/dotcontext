# ── lib/marketplace/bundle.sh ─────────────────────────────────────────────────
#
# Resolves the transitive set of items + files for a given bundle id.
#
# Public API:
#   mp_bundle_resolve_ids <id>           # echoes ids (item + transitive deps)
#   mp_bundle_resolve_files <id>         # echoes "src<TAB>dest" pairs (deduped)
#
# Implementation: depth-first walk of depends_on, deduping via a sorted list
# (no associative arrays in Bash 3.2). For typical bundle depth (≤2), this is
# fast enough.

mp_bundle_resolve_ids() {
  local root_id="$1"
  local seen=""
  local stack="$root_id"
  local out=""

  while [ -n "$stack" ]; do
    # Pop first id from stack.
    local cur="${stack%%$'\n'*}"
    if [ "$stack" = "$cur" ]; then
      stack=""
    else
      stack="${stack#*$'\n'}"
    fi
    [ -z "$cur" ] && continue

    # Skip if already seen.
    case "$seen" in
      *"|$cur|"*) continue ;;
    esac
    seen="${seen}|$cur|"
    out="${out}${cur}"$'\n'

    # Push deps.
    local dep
    while IFS= read -r dep; do
      [ -z "$dep" ] && continue
      stack="${stack}${dep}"$'\n'
    done <<EOF
$(mp_manifest_depends_on "$cur")
EOF
  done

  printf '%s' "$out"
}

mp_bundle_resolve_files() {
  local root_id="$1"
  local ids
  ids="$(mp_bundle_resolve_ids "$root_id")"
  local id
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    mp_manifest_files "$id"
  done <<EOF
$ids
EOF
}
