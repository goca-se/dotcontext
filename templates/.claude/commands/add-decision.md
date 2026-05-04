# Add Decision

Create and populate a new Architectural Decision Record (ADR) using schema 2.0.

**Usage:** `/add-decision [title or topic]`

## Process

### 1. Get Decision Topic

If `$ARGUMENTS` is empty, **use AskUserQuestion tool** to ask:
- "What is the architectural decision about?"

### 2. Detect Schema in Project

Look at existing ADRs in `.context/decisions/`. If any have `**Schema:** 2.0`, the project already uses schema 2.0 — proceed without warning. If all existing ADRs are v1.0 (no Schema line), this is the project's first v2.0 ADR — display this warning once before continuing:

> ℹ️ This project's existing ADRs use schema v1. New ADRs (including this one) will use v2 going forward — readers will see two formats. This is intentional; v1 ADRs are not migrated.

### 3. Find Next Number

Check `.context/decisions/` for existing ADRs and determine the next number (001, 002, 003...).

### 4. Gather Context (use AskUserQuestion in 4-6 calls)

Schema 2.0 needs more substance than v1. Ask the user:

1. **Context** — "What problem or need prompted this decision? What forces are at play?"
2. **Stakeholders** — "Who is affected if this decision is wrong? (Be specific about roles or teams, not just 'the team'.)"
3. **Alternatives** — "What 2-4 alternatives were considered? For each, what are the pros, cons, and the reason it was rejected?"
4. **Trade-offs Accepted** — "What are you explicitly giving up by choosing this? Name pain points you accept rather than wishing them away."
5. **Validation Criteria** — "How will you know — six months from now — whether this decision was right or wrong? Name concrete signals: metrics, observations, time horizons."
6. **Related ADRs** — "Are there existing ADRs this affects or is affected by? (Optional — answer 'none' if not.)"

Use multiSelect: false unless the user says they want to provide multiple alternatives.

### 5. Populate the ADR

Write `.context/decisions/NNN-[slug].md` using this format. Today's date should be in YYYY-MM-DD format.

```markdown
# ADR-NNN: [Title]

**Status:** Accepted
**Date:** YYYY-MM-DD
**Version:** 1.0
**Schema:** 2.0
**Deciders:** [user-supplied or detected from git config]
**Stakeholders:** [from question 2]

## Context

[From question 1]

## Decision

[Synthesize the chosen option from the user's answers]

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| [name] | [pros] | [cons] | [reason] |
| [name] | [pros] | [cons] | [reason] |

## Trade-offs Accepted

[From question 4]

## Validation Criteria

[From question 5]

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Risks:** ...

## Related ADRs

- ADR-XXX: ... (or "None")

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial decision |
```

### 6. Update Index

Update `.context/decisions/README.md` to include the new ADR in the index table. The index table has a `Schema` column — set it to `2.0` for the new entry.

## Output

```
Created: .context/decisions/NNN-[slug].md

ADR-NNN: [Title]
Status: Accepted
Schema: 2.0

Summary: [1-2 sentence summary of the decision]
```

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
