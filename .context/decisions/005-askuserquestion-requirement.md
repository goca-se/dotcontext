# ADR-005: Mandatory AskUserQuestion Tool Usage

**Status:** Accepted
**Date:** 2025-02-02
**Version:** 2.0
**Deciders:** Gocase Team

## Context

When AI assistants work on tasks, they often make assumptions about user intent. This can lead to implementations that don't match what the user wanted, wasted effort, and frustration. We needed a way to ensure the AI gathers requirements before proceeding — without falling into the opposite trap of forcing question fatigue on requests that are already clear.

## Decision

All slash commands must instruct Claude to use the `AskUserQuestion` tool to clarify requirements before proceeding with significant work — but the number of questions is driven by a **clarity assessment**, not a fixed quota.

### Clarity Assessment

Before asking anything, Claude evaluates whether the request is already clear. A request is clear when Claude can:
- See the connections between premises, examples, and conclusions
- Reformulate the goal in its own words without effort
- Apply the same idea in a different context
- Identify no internal "wait, there's a jump here I don't follow" moment

Clarity is a state of structural visibility — it does not guarantee truth, only intelligibility. If the request passes this test, **proceed with zero questions**. Otherwise, ask N questions (any N ≥ 1) that target the specific gaps — never a fixed quota.

### Examples

- `/generate-prp` runs a clarity assessment first and asks N clarifying questions (0..N) — only the ones that genuinely unblock ambiguity
- `/setup-context` asks about unclear architectural patterns
- `/add-decision` asks about context and alternatives considered

The root `CLAUDE.md` also includes this as Critical Rule #1:
> "Always ask before assuming - When there is ambiguity, multiple valid approaches, or decisions to be made, use the AskUserQuestion tool to clarify before proceeding."

## Alternatives Considered

1. **Let AI decide when to ask without criteria** - Inconsistent behavior, often skips questions
2. **Fixed quota of N questions (e.g., always 10)** - Rejected in v2.0: produces friction on simple requests and rewards padding over substance
3. **Fixed question templates** - Too rigid, may not fit all projects
4. **No enforcement** - Users would get implementations that don't match intent

## Consequences

### Positive
- Users get exactly what they want (requirements are clarified upfront)
- Reduces wasted effort from wrong assumptions
- Creates a conversation before implementation
- Documented in decision compliance system

### Negative
- Adds friction (users must answer questions)
- May feel slow for simple tasks
- Questions must be well-crafted to be useful

### Risks
- Users may get question fatigue
- Mitigation: Keep questions focused, allow skipping for simple tasks

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-02-02 | Initial decision |
| 2.0 | 2026-05-21 | Replaced fixed "10 questions" quota in `/generate-prp` with clarity-assessment policy (0..N questions). Selectively absorbed ideas from spec-driven-build skill without adopting its full ceremony. |

## Related
- ADR-004: Claude Code integration
- ADR-011: Test-Driven Bug Fixing Pattern (partial exception — `/fix-bug` skips initial questions)
