# ADR-007: CLI Simplification - Remove Add Commands

**Status:** Accepted
**Date:** 2026-02-02
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

The dotcontext CLI had two ways to add context files:

1. **CLI commands** (`dotcontext add decision/skill/prp/command`) - created empty templates
2. **Claude Code commands** (`/add-*`) - asked questions and populated with context

This created redundancy and confusion. Users had to choose between:
- Fast but empty templates (CLI)
- Slower but intelligent population (Claude Code)

Since the target audience always has Claude CLI installed, and the value proposition is AI-assisted context documentation, the template-only approach added little value.

## Decision

Remove all `add` commands from the CLI:
- ~~`dotcontext add decision`~~
- ~~`dotcontext add skill`~~
- ~~`dotcontext add prp`~~
- ~~`dotcontext add command`~~

Keep only structural commands in CLI:
- `dotcontext init` - creates structure + opens Claude with `/setup-context`
- `dotcontext update` - updates CLI and templates

All content creation is done through Claude Code slash commands that ask clarifying questions and populate files intelligently.

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
| 1.0 | 2026-02-02 | Initial decision |

## Related
- ADR-006: Auto-run /setup-context on Init
- ADR-004: Claude Code integration
