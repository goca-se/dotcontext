# ADR-006: Auto-run /setup-context on Init

**Status:** Accepted
**Date:** 2026-02-02
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

After running `dotcontext init`, users had to manually:
1. Open Claude Code (`claude`)
2. Run `/setup-context`

This added friction to the onboarding experience. Since the target audience already uses Claude Code, integrating the setup step makes sense.

## Decision

After creating the directory structure and downloading templates, `dotcontext init` automatically opens Claude Code in interactive mode with the `/setup-context` command.

```bash
claude "/setup-context"
```

A `--no-setup` flag allows users to skip this step if they prefer manual control.

## Alternatives Considered

1. **Keep manual setup** - More control but higher friction
2. **Use `claude -p` (print mode)** - Non-interactive, but `/setup-context` uses `AskUserQuestion` which requires interaction
3. **Pipe command via stdin** - Adds complexity, less reliable

## Consequences

### Positive
- Smoother onboarding: one command does everything
- Users immediately see the setup process working
- Demonstrates the Claude Code integration value

### Negative
- Requires Claude CLI to be installed
- Init no longer returns to shell immediately
- Users might not realize setup is running

### Mitigations
- Check if `claude` command exists before calling
- Show clear message: "Running setup-context..."
- `--no-setup` flag for those who want manual control

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-02 | Initial decision |

## Related
- ADR-001: Single bash executable
- ADR-004: Claude Code integration
