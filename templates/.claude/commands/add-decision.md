# Add Decision

Create and populate a new Architectural Decision Record (ADR).

**Usage:** `/add-decision [title or topic]`

## Process

### 1. Get Decision Topic

If `$ARGUMENTS` is empty, **use AskUserQuestion tool** to ask:
- "What is the architectural decision about?"

### 2. Find Next Number

Check `.context/decisions/` for existing ADRs and determine the next number (001, 002, 003...).

### 3. Create ADR File

Create `.context/decisions/NNN-[slug].md` using the Write tool.

### 4. Gather Context

**Use AskUserQuestion tool** to ask 3-4 clarifying questions about:
- What problem or need prompted this decision?
- What alternatives were considered?
- What are the main trade-offs?
- Any constraints that influenced the choice?

### 5. Populate the ADR

Fill the ADR with:

```markdown
# ADR-NNN: [Title]

**Date:** [today's date]
**Status:** Accepted

## Context

[Why this decision was needed - based on user's answers]

## Alternatives Considered

### Option 1: [Name]
- **Pros:** ...
- **Cons:** ...

### Option 2: [Name]
- **Pros:** ...
- **Cons:** ...

## Decision

[What was decided and why this option was chosen]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Trade-off 1]
- [Trade-off 2]

### Risks
- [Risk and mitigation]
```

### 6. Update Index

Update `.context/decisions/README.md` to include the new ADR in the index table.

## Output

```
Created: .context/decisions/NNN-[slug].md

ADR-NNN: [Title]
Status: Accepted

Summary: [1-2 sentence summary of the decision]
```

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
