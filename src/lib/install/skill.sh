# ── lib/install/skill.sh ──────────────────────────────────────────────────────
#
# Skill install/remove. Same mechanic as command-bundle (file copy + lockfile).
# Kept as its own file so handler dispatch is consistent across types.

mp_install_skill() { mp_install_files "$@"; }
mp_remove_skill()  { mp_remove_files  "$@"; }
