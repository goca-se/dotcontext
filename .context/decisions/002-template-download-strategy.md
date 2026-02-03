# ADR-002: Template Download Strategy

**Status:** Accepted
**Date:** 2025-01-01
**Version:** 1.0
**Deciders:** Gocase Team

## Context

dotcontext needs to create a standardized directory structure in user projects. The templates define the structure of CLAUDE.md, CONTEXT.md, ADR format, skill format, etc. We needed to decide how to distribute these templates.

## Decision

Download templates from GitHub's raw content URL at runtime during `dotcontext init`.

Templates are fetched from:
```
https://raw.githubusercontent.com/goca-se/dotcontext/main/templates/
```

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

## Related
- ADR-001: Single bash executable
- ADR-003: Safe update behavior
