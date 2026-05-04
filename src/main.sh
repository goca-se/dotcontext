# ── Main Routing ──────────────────────────────────────────────────────────────

case "${1:-}" in
  init) shift; cmd_init "$@" ;;
  update) shift; cmd_update "$@" ;;
  doctor)
    print_yellow "dotcontext doctor is deprecated and was removed in this release."
    print_gray  "Run 'dotcontext' (no args) and switch to the Status tab."
    exit 0
    ;;
  completion)
    print_yellow "dotcontext completion was removed in this release."
    print_gray  "See README for shell-completion guidance."
    exit 0
    ;;
  --version|-v) echo "dotcontext $VERSION" ;;
  --help|-h) cmd_help ;;
  "") cmd_browse ;;
  *) print_red "Unknown command: $1. Run 'dotcontext --help' for usage."; exit 1 ;;
esac
