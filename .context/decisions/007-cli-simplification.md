# ADR-007: CLI Simplification - Remove Add Commands

**Status:** Accepted
**Date:** 2026-02-02
**Version:** 2.0
**Deciders:** Nicholas (Gocase)

## Context

The dotcontext CLI had two ways to add context files:

1. **CLI commands** (`dotcontext add decision/skill/prp/command`) - created empty templates
2. **Claude Code commands** (`/add-*`) - asked questions and populated with context

This created redundancy and confusion. Users had to choose between:
- Fast but empty templates (CLI)
- Slower but intelligent population (Claude Code)

Since the target audience always has Claude CLI installed, and the value proposition is AI-assisted context documentation, the template-only approach added little value.

**v2.0 update:** With the marketplace TUI (ADR-014), the CLI is further trimmed. `dotcontext doctor` and `dotcontext completion` are removed; `doctor` becomes the Status tab inside the TUI. Running `dotcontext` with no arguments now opens the marketplace TUI rather than printing help.

## Decision

### v1.0 — Remove add commands

Remove all `add` commands from the CLI:
- ~~`dotcontext add decision`~~
- ~~`dotcontext add skill`~~
- ~~`dotcontext add prp`~~
- ~~`dotcontext add command`~~

### v2.0 — Trim further; no-args opens TUI

Final CLI surface:

```
dotcontext                 # opens marketplace TUI (no-args)
dotcontext init [...]      # creates Layer 1 + runs /setup-context
dotcontext update [...]    # updates CLI + Layer 1 + lockfile-tracked items
dotcontext --help
dotcontext --version
```

**Removed in v2.0:**
- `dotcontext doctor` — health check is now the **Status** tab in the TUI. To migrate scripts that called `doctor` for CI checks, we keep one release of deprecation: `dotcontext doctor` prints "deprecated; use `dotcontext` (Status tab) or `dotcontext --status` for headless" and exits 0. Removed entirely the release after.
- `dotcontext completion` — low usage; shell completion can be regenerated on demand by users who need it (instructions in README).

All content creation continues through Claude Code slash commands that ask clarifying questions and populate files intelligently.

## Alternatives Considered

1. **Keep both** - Redundant, confusing which to use
2. **CLI calls Claude -p** - Would lose interactivity, questions wouldn't work
3. **CLI opens Claude per command** - Opens new terminal each time, disruptive

## Consequences

### Positive
- Simpler CLI with clear purpose (scaffolding + updates)
- Single way to add content (Claude Code) - no confusion
- Better content quality (AI-assisted with questions)
- Consistent with `init` behavior (opens Claude)

### Negative
- Can't add files without Claude CLI
- Slightly more steps if already in terminal

### Mitigations
- Target audience already uses Claude Code
- Templates are downloaded during `init`, so manual editing is still possible

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-02 | Initial decision (remove `add` subcommands) |
| 2.0 | 2026-04-30 | Remove `doctor` + `completion`; no-args opens marketplace TUI (PRP: marketplace-tui-and-layered-distribution) |

## Related
- ADR-006: Auto-run /setup-context on Init
- ADR-004: Claude Code integration
- ADR-014: Marketplace TUI Architecture
- ADR-015: Two-Layer Distribution Model
