# Architectural Decision Records (ADRs)

Record of significant technical decisions in this project.

## Index

| ADR | Title | Status | Schema |
|-----|-------|--------|--------|
| [001](001-example.md) | [Title] | Accepted | 2.0 |

## Template

ADRs in this project use **schema 2.0** going forward. Existing v1.0 ADRs (if any) remain unchanged — coexistence is intentional.

### Schema 2.0 (use for new ADRs)

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Version:** 1.0
**Schema:** 2.0
**Deciders:** [Names]
**Stakeholders:** [Roles/teams affected — be specific, not "the team"]

## Context

[Why was this decision needed? What forces are at play?]

## Decision

[What was decided?]

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Option A | ... | ... | ... |
| Option B | ... | ... | ... |

## Trade-offs Accepted

[What are we explicitly giving up by choosing this? Name pain points we accept rather than burying them in "Consequences/Negative".]

## Validation Criteria

[How will we know this decision was right or wrong? Concrete signals: metrics, observations, time horizons.]

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Risks:** ...

## Related ADRs

- ADR-XXX: ...

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial decision |
```

### Schema 1.0 (legacy — for reference only)

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Version:** 1.0

## Context
## Decision
## Consequences
- **Positive:** ...
- **Negative:** ...
## History
```

## Conventions

- **Numbering:** Sequential, 3 digits with leading zeros (001, 002, ...)
- **Filename:** `NNN-title-in-slug.md`
- **Status:**
  - `Proposed` - Under discussion
  - `Accepted` - Approved and in use
  - `Deprecated` - Still works but not recommended
  - `Superseded` - Replaced by another ADR (link it)

## Adding Decisions

In Claude Code, use the interactive command:
```
/add-decision
```

This will ask clarifying questions and populate the ADR with context. It detects the dominant schema in this directory and emits matching format — projects that have only v1 ADRs receive a warning when v2 is first introduced.
