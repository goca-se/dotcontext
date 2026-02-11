# ADR-005: Mandatory AskUserQuestion Tool Usage

**Status:** Accepted
**Date:** 2025-02-02
**Version:** 1.0
**Deciders:** Gocase Team

## Context

When AI assistants work on tasks, they often make assumptions about user intent. This can lead to implementations that don't match what the user wanted, wasted effort, and frustration. We needed a way to ensure the AI gathers requirements before proceeding.

## Decision

All slash commands must instruct Claude to use the `AskUserQuestion` tool to clarify requirements before proceeding with significant work.

Examples:
- `/generate-prp` asks 10 custom clarifying questions before generating the PRP
- `/setup-context` asks about unclear architectural patterns
- `/add-decision` asks about context and alternatives considered

The root `CLAUDE.md` also includes this as Critical Rule #1:
> "Always ask before assuming - When there is ambiguity, multiple valid approaches, or decisions to be made, use the AskUserQuestion tool to clarify before proceeding."

## Alternatives Considered

1. **Let AI decide when to ask** - Inconsistent behavior, often skips questions
2. **Fixed question templates** - Too rigid, may not fit all projects
3. **No enforcement** - Users would get implementations that don't match intent

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

## Related
- ADR-004: Claude Code integration
- ADR-011: Test-Driven Bug Fixing Pattern (partial exception — `/fix-bug` skips initial questions)
