# ADR-002: Template Download Strategy

**Status:** Accepted
**Date:** 2025-01-01
**Version:** 2.0
**Deciders:** Gocase Team, Nicholas (Gocase) — v2.0

## Context

dotcontext needs to create a standardized directory structure in user projects. The templates define the structure of CLAUDE.md, CONTEXT.md, ADR format, skill format, etc. We needed to decide how to distribute these templates.

**v2.0 update:** With the marketplace (ADR-015), distribution is no longer one-shot. `dotcontext init` ships Layer 1 only; Layer 2 items are downloaded on-demand from the marketplace, tracked in a lockfile (ADR-016), and resolved through a manifest. This ADR is extended to cover the two paths.

## Decision

### Layer 1 (init-time)

Download mandatory templates from GitHub's raw content URL during `dotcontext init`. Templates are fetched from:

```
https://raw.githubusercontent.com/goca-se/dotcontext/main/templates/
```

Layer 1 covers `.context/` skeleton, `CLAUDE.md`, `/setup-context`, `/add-decision`, `/add-skill`, `/add-command`, `/commit`, and `/deep-context` + agents (see ADR-015 for the full Layer 1 list).

### Layer 2 (marketplace, on-demand)

Marketplace items (Layer 2) are described in `marketplace/manifest.json`, which lives in the dotcontext repo and is either embedded in the bundled `dotcontext` binary or fetched from GitHub. When the user selects an item in the TUI:

1. Resolve the item (and its `depends_on` graph) from the manifest
2. Download each `files[].src` from `https://raw.githubusercontent.com/goca-se/dotcontext/main/<src>`
3. Copy to the destination resolved by scope (local `<repo>/.claude/...` or global `~/.claude/...`)
4. Record the install in the lockfile (ADR-016)

The manifest itself uses the same raw-content URL pattern. CLI versions and manifest versions are independent — a CLI update does not force a manifest re-download (manifest is fetched fresh on each TUI open by default).

## Alternatives Considered

1. **Embed templates in the script** - Would make the script very long, harder to maintain
2. **Separate installable package** - Would require npm/pip, complicates installation
3. **Local template cache** - Adds complexity, stale templates problem
4. **Git clone** - Requires git, downloads entire repo

## Consequences

### Positive
- Templates can be updated independently of CLI
- Keeps main script small and focused
- Users always get latest templates on init
- Easy to add new templates without CLI update

### Negative
- Requires internet connection during init
- Depends on GitHub availability
- Users may get unexpected changes to templates

### Risks
- GitHub rate limiting for raw.githubusercontent.com
- Breaking changes to templates affect existing users
- Mitigation: Version templates with CLI releases, use `--templates` update flag

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial decision |
| 2.0 | 2026-04-30 | Extended to cover Layer 2 marketplace download via manifest + lockfile (PRP: marketplace-tui-and-layered-distribution) |

## Related
- ADR-001: Single bash executable
- ADR-003: Safe update behavior
- ADR-015: Two-Layer Distribution Model
- ADR-016: Lockfile Format and Scope Resolution
