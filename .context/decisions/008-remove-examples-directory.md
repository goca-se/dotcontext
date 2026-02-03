# ADR-008: Remove examples/ Directory

**Status:** Accepted
**Date:** 2026-02-02
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

The `.context/examples/` directory was designed to hold reference code files. However:

1. **Skills already include examples** - Each skill has an "Examples" section with code snippets in context
2. **Decisions include code when needed** - ADRs can reference specific code patterns
3. **In practice, it stayed empty** - Users rarely added standalone example files

The directory added structure without value.

## Decision

Remove `.context/examples/` from the scaffold structure.

Examples should be embedded in:
- Skills (with explanation and anti-patterns)
- ADRs (when documenting patterns)
- CONTEXT.md (for domain-specific code)

## Consequences

### Positive
- Simpler directory structure
- Examples are co-located with their context
- One less empty directory to maintain

### Negative
- No dedicated place for standalone reference files
- Migration needed for projects using examples/

### Mitigation
- Users can still create `examples/` manually if needed
- Existing projects won't break (directory just won't be created for new projects)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-02 | Initial decision |

## Related
- ADR-007: CLI Simplification
