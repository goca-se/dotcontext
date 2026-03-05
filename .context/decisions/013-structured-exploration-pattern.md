# ADR-013: Structured Exploration Pattern

**Status:** Accepted
**Date:** 2026-03-05
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

The `/deep-context` command originally used a 5-agent model (Scope Guardian, Primary Explorer, Cross-Repo Explorer, Cross-Repo Validator, Reviewer) designed for cross-repo business rule discovery. While effective for that use case, the model had limitations:

- No structured progression from high-level to low-level analysis
- The Scope Guardian agent narrowed too early, sometimes missing relevant areas
- No dedicated data flow tracing step
- The 5-agent model was optimized for cross-repo validation, but most users explore a single repo

We needed a more systematic exploration approach that works well for both single-repo and cross-repo analysis.

## Decision

Restructure `/deep-context` to use a **4-step structured exploration flow**:

| Step | Agent | Purpose | Execution |
|------|-------|---------|-----------|
| 1 | Overview Agent | High-level architecture summary, key files, entry points | Parallel with Step 2 |
| 2 | Subsystem Agent | Map modules, purposes, interdependencies | Parallel with Step 1 |
| 3 | Drill Agent | Targeted investigation of relevant areas | Sequential (needs 1+2) |
| 4 | Data Flow Agent | Trace information movement through system | Sequential (needs 1-3) |

### Execution Pattern
- **Phase 1 (parallel):** Steps 1 + 2 run simultaneously — both do broad exploration
- **Phase 2 (sequential):** Step 3 runs after Phase 1 — needs overview + subsystem map to focus
- **Phase 3 (sequential):** Step 4 runs after Step 3 — needs targeted findings to trace flows

### Cross-Repo Support
Cross-repo analysis is integrated into Steps 1 and 2 via appended instructions when a related repo is provided. This eliminates the need for dedicated cross-repo agents while preserving the capability.

### Final Compilation
The orchestrator (command prompt) compiles the final document directly from all 4 agent outputs, replacing the dedicated Reviewer agent. This reduces agent count and gives the orchestrator full control over output quality.

## Alternatives Considered

1. **Keep 5-agent model** — Status quo. Rejected: not structured progressively, Scope Guardian narrows too early.
2. **3-step model (skip data flow)** — Simpler but loses valuable data flow tracing. Rejected: data flow analysis is one of the most actionable outputs.
3. **6-step model (add security + performance)** — Too many agents, diminishing returns, context window pressure. Rejected: over-scoped.

## Consequences

### Positive
- Structured progression ensures thorough exploration (high-level → detailed → flow)
- Each step builds on previous outputs, creating richer context for later agents
- Data flow tracing produces actionable architectural insights
- Simpler cross-repo integration (no dedicated cross-repo agents needed)
- Fewer agents (4 vs 5) reduces context window pressure

### Negative
- Steps 3+4 are sequential, which adds latency compared to full parallelism
- Step 4 receives outputs from all prior steps, creating large prompt sizes
- Removing dedicated Reviewer agent means orchestrator must handle quality filtering

### Risks
- Context overflow for Step 4 agent receiving all prior outputs
- Mitigation: Each agent uses focused searches; Step 1 identifies key areas early; `max_turns: 30` prevents runaway exploration

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-05 | Initial decision |

## Related
- ADR-009: Multi-Agent Orchestration Pattern (updated execution model)
- ADR-012: Agent File Extraction Pattern (new agent files follow this pattern)
