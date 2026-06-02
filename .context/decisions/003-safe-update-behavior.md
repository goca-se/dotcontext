# ADR-003: Safe Update Behavior

**Status:** Accepted
**Date:** 2025-01-15
**Version:** 2.0
**Deciders:** Gocase Team

## Context

When users run `dotcontext update --templates`, we need to decide how to handle existing files. Users may have customized their CLAUDE.md, added content to CONTEXT.md, or modified templates. Blindly overwriting would lose their work.

The original v1.0 model was "only add new files; pass `--force` to overwrite everything." In practice the toolkit evolved to a finer-grained split between dotcontext-owned files and user-owned files, making a single blunt `--force` overwrite both unsafe and unnecessary.

## Decision

Files fall into two classes, handled differently on update:

- **Seed files** (user-owned: `CLAUDE.md`, `CONTEXT.md`, `decisions/README.md`, `bug-reproduction/SKILL.md`, `feature.md`, …) — created once if missing and **never overwritten**, protecting user customizations.
- **Managed files** (dotcontext-owned: commands, agents, statusline, hooks) — always offered for update. The update shows a per-file diff and prompts before applying; stale managed files are pruned declaratively.

Flags:

```bash
# Safe default: add new seeds, show diffs and prompt for managed changes
dotcontext update --templates

# Non-interactive: auto-accept managed updates (seeds still never overwritten)
dotcontext update --templates --yes

# Preview only: show what would change
dotcontext update --templates --dry-run
```

There is **no `--force` flag** — it was removed (it had degenerated into a plain alias for `--yes`). User-owned seeds are never force-overwritten by design; to reset one, delete it and re-run update.

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
| 2.0 | 2026-06-02 | Replace the blunt `--force` overwrite with the seed/managed split (diff + prompt for managed, create-only for seeds); document removal of `--force` in favor of `--yes`/`--dry-run` |

## Related
- ADR-002: Template download strategy
- ADR-014: Automated release pipeline & single-source versioning
