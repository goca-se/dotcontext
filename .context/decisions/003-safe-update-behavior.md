# ADR-003: Safe Update Behavior

**Status:** Accepted
**Date:** 2025-01-15
**Version:** 1.0
**Deciders:** Gocase Team

## Context

When users run `dotcontext update --templates`, we need to decide how to handle existing files. Users may have customized their CLAUDE.md, added content to CONTEXT.md, or modified templates. Blindly overwriting would lose their work.

## Decision

By default, template updates only add new files that don't exist. Existing files are never overwritten unless the user explicitly passes `--force`.

```bash
# Safe: only adds new files
dotcontext update --templates

# Destructive: overwrites everything
dotcontext update --templates --force
```

## Alternatives Considered

1. **Always overwrite** - Would lose user customizations
2. **Interactive prompts per file** - Tedious for many files
3. **Backup before overwrite** - Adds complexity, users may not know to restore
4. **Diff and merge** - Complex to implement in bash

## Consequences

### Positive
- User customizations are preserved by default
- Explicit `--force` prevents accidental data loss
- Simple mental model: default is safe
- New templates from updates are still available

### Negative
- Users with outdated templates may not get improvements
- Must document that `--force` is needed for full reset
- No way to selectively update one template

### Risks
- Users may not realize their templates are outdated
- Mitigation: Add `dotcontext status` command to check for template drift (future)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-15 | Initial decision |

## Related
- ADR-002: Template download strategy
