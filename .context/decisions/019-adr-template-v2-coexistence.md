# ADR-019: ADR Template v2 (Coexistence)

**Status:** Accepted
**Date:** 2026-04-30
**Version:** 1.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** anyone authoring or reading ADRs in this project, downstream projects using `/add-decision`

## Context

The ADR template (v1.0) shipped with dotcontext has Context, Decision, Alternatives Considered, Consequences (Positive/Negative/Risks), History, and Related sections. Reviewing the existing 13 ADRs, three gaps emerged:

1. **Stakeholders are implicit.** Who is affected if this decision is wrong? "Gocase Team" is too coarse.
2. **Trade-offs are folded into Consequences/Negative.** That hides the *deliberate* "we accept giving up X to gain Y" reasoning, which is the most valuable part of a decision record six months later.
3. **There's no validation criteria.** ADRs don't say *how we'll know if this was right*. Without that, decisions can never be revisited objectively.

## Decision

Introduce **ADR template v2.0**, which adds:

- `**Schema:** 2.0` line in the header (so tooling can detect the version)
- `**Stakeholders:**` line — roles or teams affected
- A **Trade-offs Accepted** section between Alternatives and Validation, naming what we deliberately give up
- A **Validation Criteria** section before Consequences — concrete signals (metrics, observations, time horizons) for whether the decision worked
- The Consequences section is shortened to a quick Positive / Negative / Risks summary (not the same as Trade-offs Accepted)
- The "Alternatives Considered" section uses a comparison table (option, pros, cons, why rejected) rather than a numbered list

### v2 template

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Version:** 1.0
**Schema:** 2.0
**Deciders:** [Names]
**Stakeholders:** [Roles/teams affected]

## Context
## Decision
## Alternatives Considered
| Option | Pros | Cons | Why rejected |
## Trade-offs Accepted
## Validation Criteria
## Consequences
- **Positive:**
- **Negative:**
- **Risks:**
## Related ADRs
## History
| Version | Date | Changes |
```

### Coexistence policy

- Existing ADRs (001–013) **remain in v1.0 schema**. We do not migrate them. Their decisions are still valid.
- New ADRs from this date forward use v2.0.
- `/add-decision` detects the dominant schema in `.context/decisions/` and emits v2 by default. If a project has only v1 ADRs, the command warns: *"This project's existing ADRs use schema v1. New ADRs will use v2 — readers will see two formats."*
- `CLAUDE.md`'s decision-compliance instruction reads ADRs regardless of schema. The instruction does not depend on specific section headings.

### Why coexistence rather than migration

Migrating 13 existing ADRs would require synthesizing Stakeholders / Trade-offs / Validation that weren't decided at the time. That fabricates history. Better to leave them as the authentic record of what was decided when, and write better records going forward.

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Keep v1 | No migration cost; consistent format | Misses high-value sections (Trade-offs, Validation) | Status quo problem |
| Migrate all to v2 | Consistent format; full validation criteria everywhere | Fabricates history; high effort across 13 ADRs | Inauthentic |
| Coexistence (chosen) | Authentic + better future records | Two formats in one repo | Best balance |
| Optional v2 (per-author choice) | Maximum flexibility | Inconsistency without principle | Worse than picking one rule |

## Trade-offs Accepted

- **Two formats coexist.** Readers will see different section sets across ADRs. We accept this as a sign of a maturing template, documented in the README.
- **`/add-decision` carries logic to detect schema.** Slightly more complex command than "always emit v2." We accept the complexity for the benefit of authentic transitions.
- **No automated validation that v2 ADRs actually fill the new sections.** A lazy author could leave Stakeholders empty. We accept this — peer review catches it.

## Validation Criteria

- New ADRs created via `/add-decision` after this PRP are v2 (verified by grep for `**Schema:** 2.0`).
- Six months in, at least 80% of new ADRs have non-empty Trade-offs Accepted and Validation Criteria sections.
- Decision compliance check (CLAUDE.md → "before implementing, check decisions/") still works on v1 + v2 ADR mix without modification.

## Consequences

- **Positive:** richer decision records; explicit trade-offs and validation make ADRs more useful for review.
- **Negative:** mixed format in `.context/decisions/`; readers must tolerate two layouts.
- **Risks:** v2 sections become checkbox theater (filled in for the form). Mitigated by review culture, not tooling.

## Related ADRs

- ADR-005: Mandatory AskUserQuestion Tool Usage (`/add-decision` uses AskUserQuestion to fill the new fields)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-30 | Initial decision |
