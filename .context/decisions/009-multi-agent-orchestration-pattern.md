# ADR-009: Multi-Agent Orchestration Pattern

**Status:** Accepted
**Date:** 2026-02-10
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

The `/deep-context` command requires 5 specialized agents working together to discover business rules across repositories. We needed to decide how agents communicate results and coordinate execution.

The agents have distinct roles (scope guardian, primary explorer, cross-repo explorer, validator, reviewer) and must execute in a specific order: some in parallel (Phase 1), then sequential processing of combined results (Phases 2-3).

## Decision

Use Claude Code's **Task tool with direct returns** for agent orchestration:

1. **Phase 1 (parallel):** Agent 1 (Compliance), Agent 2 (Explorer), and Agent 3 (Cross-Repo) launch simultaneously via Task tool
2. **Phase 2 (sequential):** Agent 4 (Validator) receives Agent 2 + Agent 3 outputs as prompt context
3. **Phase 3 (sequential):** Agent 5 (Reviewer) receives ALL agent outputs, produces final document

Each agent returns its findings as structured text in the Task tool response. The orchestrator (command prompt) passes results between phases by including previous agent outputs in subsequent agent prompts.

### Agent Communication
- **No temp files** — all data flows through Task tool return values
- **No shared state** — agents are independent; the orchestrator is the only coordinator
- **Structured output** — each agent returns findings in a defined markdown format for easy parsing

## Alternatives Considered

1. **Temp files on disk** — Agents write to `.context/discoveries/.tmp/`. Rejected: adds cleanup complexity, file I/O overhead, potential race conditions.
2. **Single sequential agent** — One agent does everything step by step. Rejected: much slower, loses parallelism benefits, single point of failure.
3. **Real-time agent communication** — Agents communicate mid-execution. Rejected: not supported by Task tool, over-engineered for this use case.

## Consequences

### Positive
- No file system side effects during analysis
- Natural parallelism using Task tool's concurrent execution
- Clear data flow: orchestrator controls what each agent sees
- Easy to add/remove agents without changing infrastructure

### Negative
- Large prompt sizes for later agents (receive all prior outputs)
- No persistent state between runs (each execution is fresh)
- Context window limits may constrain very large codebases

### Risks
- Context overflow for Agent 5 receiving all outputs
- Mitigation: Agents use focused searches (Grep/Glob, not full file reads); Agent 1 narrows scope early

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-10 | Initial decision |
| 1.1 | 2026-03-04 | Agent prompts extracted to `.claude/agents/` files (see ADR-012) |
| 1.2 | 2026-03-05 | Deep-context restructured from 5-agent to 4-step exploration flow (see ADR-013) |

## Related
- ADR-004: Claude Code Integration via Slash Commands
- ADR-005: Mandatory AskUserQuestion Tool Usage
- ADR-012: Agent File Extraction Pattern
