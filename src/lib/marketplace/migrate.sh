# ── lib/marketplace/migrate.sh ────────────────────────────────────────────────
#
# Auto-registration of items installed by pre-v0.15 dotcontext.
#
# See ADR-018 (Existing User Migration via Auto-Registration). Detection rule
# in this implementation: a bundle's *all* destination files must exist at the
# expected paths. Hash-based detection is deferred — the simpler rule covers
# the common case and accepts the documented false-positive edge case (a user
# who happens to have all files of a bundle by hand).
#
# Public API:
#   mp_migrate_run                   # runs migration; echoes summary
#   mp_migrate_should_run            # exit 0 if marker missing (one-time)
#   mp_migrate_mark_done             # writes the marker file

MP_MIGRATE_MARKER="$HOME/.dotcontext/migration-v015-done"

mp_migrate_should_run() {
  [ ! -f "$MP_MIGRATE_MARKER" ]
}

mp_migrate_mark_done() {
  mkdir -p "$(dirname "$MP_MIGRATE_MARKER")"
  : > "$MP_MIGRATE_MARKER"
}

# Returns 0 if all files of bundle <id> exist under <root>.
_mp_migrate_bundle_present() {
  local id="$1" root="$2"
  local files
  files="$(mp_manifest_files "$id")"
  [ -z "$files" ] && return 1  # bundle has no files (e.g., MCP) — handled separately
  local pair dest
  while IFS=$'\t' read -r _ dest; do
    [ -z "$dest" ] && continue
    if [ ! -f "$root/$dest" ]; then
      return 1
    fi
  done <<EOF
$files
EOF
  return 0
}

# Lists destination paths for a bundle, relative to scope root.
_mp_migrate_bundle_dest_list() {
  local id="$1"
  local pair dest
  while IFS=$'\t' read -r _ dest; do
    [ -z "$dest" ] && continue
    printf '%s\n' "$dest"
  done <<EOF
$(mp_manifest_files "$id")
EOF
}

# Scans local + global scopes for bundles whose files all exist.
# Registers each into the appropriate lockfile.
mp_migrate_run() {
  mp_manifest_load 2>/dev/null || return 1

  local local_root global_root
  local_root="$(mp_scope_root local)"
  global_root="$(mp_scope_root global)"

  local registered_local=0
  local registered_global=0
  local id

  while IFS= read -r id; do
    [ -z "$id" ] && continue
    local type
    type="$(mp_manifest_field "$id" type)"

    case "$type" in
      command-bundle|skill|script)
        # File-based items: check each scope.
        if mp_lock_has local "$id" 2>/dev/null; then :; else
          if [ -d "$local_root/.context" ] && _mp_migrate_bundle_present "$id" "$local_root"; then
            local files
            files="$(_mp_migrate_bundle_dest_list "$id")"
            mp_lock_add local "$id" "auto-registered" "$files"
            registered_local=$(( registered_local + 1 ))
          fi
        fi
        if mp_lock_has global "$id" 2>/dev/null; then :; else
          if _mp_migrate_bundle_present "$id" "$global_root"; then
            local files
            files="$(_mp_migrate_bundle_dest_list "$id")"
            mp_lock_add global "$id" "auto-registered" "$files"
            registered_global=$(( registered_global + 1 ))
          fi
        fi
        ;;
      mcp|hook)
        # MCPs/hooks: defer to v2. We can't safely detect without parsing
        # settings.json deeply (user may have added them by hand).
        :
        ;;
      external-cli)
        # External CLIs: detect by verify_command success.
        if ! mp_lock_has machine "$id" 2>/dev/null; then
          local verify
          verify="$(mp_manifest_verify_command "$id")"
          if [ -n "$verify" ] && eval "$verify" >/dev/null 2>&1; then
            mp_lock_add_cli "$id" "auto-registered" "unknown"
            # Counted in global summary for the user (not strictly local).
            registered_global=$(( registered_global + 1 ))
          fi
        fi
        ;;
    esac
  done <<EOF
$(mp_manifest_ids)
EOF

  local total=$(( registered_local + registered_global ))
  if [ "$total" -gt 0 ]; then
    printf '\n  \033[36mDetected %d item(s) from previous installation.\033[0m\n' "$total"
    printf '  Registered in marketplace state. Run \033[1mdotcontext\033[0m to manage.\n\n'
  fi

  mp_migrate_mark_done
}

mp_migrate_if_needed() {
  if mp_migrate_should_run; then
    mp_migrate_run
  fi
}
