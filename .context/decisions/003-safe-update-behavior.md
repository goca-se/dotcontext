# ADR-003: Safe Update Behavior

**Status:** Accepted
**Date:** 2025-01-15
**Version:** 2.0
**Deciders:** Gocase Team, Nicholas (Gocase) — v2.0

## Context

When users run `dotcontext update --templates`, we need to decide how to handle existing files. Users may have customized their CLAUDE.md, added content to CONTEXT.md, or modified templates. Blindly overwriting would lose their work.

**v2.0 update:** With the marketplace (ADR-015) and lockfile (ADR-016), update behavior splits into two regimes — *managed templates* (Layer 1, always behind a content lock) and *lockfile-tracked items* (Layer 2, where the lockfile says "I installed version X"). Untracked files keep the original v1.0 behavior.

## Decision

### Untracked files (original behavior)

By default, template updates only add new files that don't exist. Existing files are never overwritten unless the user explicitly passes `--force`.

```bash
# Safe: only adds new files
dotcontext update --templates

# Destructive: overwrites everything
dotcontext update --templates --force
```

### Lockfile-tracked items (v2.0)

For items recorded in `.dotcontext-state.json` or `~/.dotcontext/state.json`:

- If the manifest version is **newer** than the installed version, `dotcontext update` shows a terraform-style preview ("`code-review` 1.0.0 → 1.1.0: 4 files would change"), then asks for confirmation.
- If the user accepts, files are overwritten and the lockfile version is updated.
- `--force` skips the preview prompt for tracked items (still safe — only updates lockfile-tracked paths).
- Items with `version: "auto-registered"` (ADR-018) are **not** offered for upgrade automatically; they need an explicit `dotcontext update --reinstall <id>` because we don't know what version the user originally had.

### Managed templates (Layer 1)

Layer 1 templates (e.g., `.context/decisions/README.md`) are *always* updated to match the latest manifest. The user already opted in to the methodology by running `init`; we own those files.

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
| 2.0 | 2026-04-30 | Distinguish lockfile-tracked items (preview + confirm on version change) from untracked files (original behavior) (PRP: marketplace-tui-and-layered-distribution) |

## Related
- ADR-002: Template download strategy
- ADR-015: Two-Layer Distribution Model
- ADR-016: Lockfile Format and Scope Resolution
- ADR-018: Existing User Migration via Auto-Registration
