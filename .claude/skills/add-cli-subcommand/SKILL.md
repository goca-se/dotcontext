# Skill: Add a New CLI Subcommand

## When to Use

Use this skill when you need to add a new subcommand to the `dotcontext` CLI (e.g., `dotcontext status`, `dotcontext validate`).

## Prerequisites

- Understanding of bash scripting
- Familiarity with the existing command structure in `dotcontext`

## Steps

### 1. Define the command function

Add a new function in the `dotcontext` script. Follow the naming convention `cmd_<name>`:

```bash
cmd_status() {
    print_header "Status"

    # Command implementation here

    print_green "✓ Status check complete"
}
```

### 2. Add to the command router

Find the case statement in `main()` and add your command:

```bash
case "$1" in
    init)
        shift
        cmd_init "$@"
        ;;
    status)  # Add new case
        shift
        cmd_status "$@"
        ;;
    # ... other commands
esac
```

### 3. Add help text

Update the `show_help()` function:

```bash
show_help() {
    echo "Usage: dotcontext <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init          Initialize context structure"
    echo "  status        Check context health"  # Add new line
    # ...
}
```

### 4. Handle arguments

Parse command-specific flags:

```bash
cmd_status() {
    local verbose=false

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_red "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Use $verbose in implementation
}
```

### 5. Use helper functions

Leverage existing helpers for consistent output:

```bash
# Colors
print_green "Success message"
print_yellow "Warning message"
print_red "Error message"
print_blue "Info message"

# Prompts
if prompt_yes_no "Continue?"; then
    # User said yes
fi

# File operations
slugify "Some Title"  # Returns "some-title"
download_file "$url" "$dest"
```

### 6. Test on multiple platforms

Test your command on:
- macOS (bash 3.2)
- Linux (bash 5.x)
- WSL (if applicable)

## Anti-Patterns

- **Don't use bashisms** - Avoid `[[ ]]`, `$'...'`, arrays (use POSIX `[ ]`, quoted strings)
- **Don't hardcode paths** - Use variables like `$CONTEXT_DIR`
- **Don't skip error handling** - Check file existence, command success
- **Don't output without color helpers** - Use `print_*` functions for consistency

## Example

From the existing `cmd_update` function:

```bash
cmd_update() {
    local update_templates=false
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --templates) update_templates=true; shift ;;
            --force) force=true; shift ;;
            *) shift ;;
        esac
    done

    if [ "$update_templates" = true ]; then
        cmd_update_templates "$force"
    else
        cmd_update_cli
    fi
}
```

## Related

- ADR-001: Single bash executable
- Critical Rule: POSIX compatibility
