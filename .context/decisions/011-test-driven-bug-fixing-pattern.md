# ADR-011: Test-Driven Bug Fixing Pattern

**Status:** Accepted
**Date:** 2026-02-10
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

Current dotcontext workflows are optimized for feature development (PRP → execute). Bug fixing has no structured approach — developers either use `/generate-prp` (too heavy, asks 10+ questions) or ask Claude directly (no test validation, no documentation).

Community feedback confirms that writing a test that reproduces the bug before attempting a fix dramatically improves outcomes. Models that write tests without seeing them fail first produce unreliable tests. The `/fix-bug` command needs to be fast and frictionless — zero questions, straight to investigation.

This creates a partial exception to ADR-005 (Mandatory AskUserQuestion), which requires all commands to ask clarifying questions before proceeding.

## Decision

Implement a test-driven bug fixing workflow via the `/fix-bug` command with these principles:

### 1. Zero Questions at Start (ADR-005 Exception)

The `/fix-bug` command does NOT ask clarifying questions at the start. The user provides a bug description (and optionally `--issue N` or `--pr N`), and the command immediately begins investigation.

**Rationale:** Bug descriptions are inherently specific — "login fails with empty password" provides enough context. Adding questions would slow down a workflow where speed matters. The user already knows what's broken.

**AskUserQuestion IS used** at the end, only for final fix selection when multiple agents succeed.

### 2. Test-First Mandatory

Before any fix attempt:
1. Investigator agent identifies root cause
2. Writes a failing test that reproduces the bug
3. Verifies the test FAILS (proving the bug exists)
4. If the test passes → stop, report failure, ask user for help

### 3. Parallel Fix Agents (All Run to Completion)

N agents (default 3) attempt fixes simultaneously with diverse strategies:
- **Conservative**: Minimal change, smallest diff
- **Minimal**: Exact line(s) causing the issue
- **Refactor**: Fix + improve surrounding code

All agents run to completion — even if one finds a fix early. This ensures the best possible fix, not just the first one.

### 4. Reviewer Selects Best Fix

A reviewer agent evaluates all results:
- 0 agents succeeded → report failure, ask user
- 1 agent succeeded → use that fix
- >1 agents succeeded → attempt to combine, or pick best
- Final fix must pass reproduction test AND full test suite

### 5. Bug Report Documentation

Every fix produces a structured report saved to `.context/bugs/YYYYMMDD-[slug].md` with root cause analysis, reproduction test, fix details, and alternatives considered.

## Alternatives Considered

1. **Ask questions first (comply with ADR-005)** — Rejected: adds friction to a workflow that benefits from speed. Bug descriptions are already specific.
2. **Single fix agent** — Rejected: parallel agents with diverse strategies produce better fixes. Cost of running 3 agents is low compared to value of finding the best fix.
3. **Stop at first successful fix** — Rejected: the first fix may not be the best. Running all agents to completion allows the reviewer to select optimal solution.
4. **No test requirement** — Rejected: fixes without tests risk not addressing root cause and leave no regression protection.

## Consequences

### Positive
- Bug fixes are validated by automated tests before being applied
- Multiple fix strategies increase likelihood of finding optimal solution
- Bug reports provide documentation for future reference
- Fast workflow — zero questions means user goes from bug description to fix with minimal friction

### Negative
- Partial exception to ADR-005 may create precedent for other commands skipping questions
- Running 3+ parallel agents uses more compute than a single fix attempt
- Requires project to have a test framework (handled by skill template)

### Risks
- Test may not reproduce the bug correctly → Mitigation: verify test fails for the RIGHT reason
- All fix agents fail → Mitigation: report partial progress, ask user for guidance
- Fix passes reproduction test but breaks other tests → Mitigation: reviewer runs full test suite

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-10 | Initial decision |

## Related
- ADR-005: Mandatory AskUserQuestion Tool Usage (partial exception documented here)
- ADR-009: Multi-Agent Orchestration Pattern (extended with "all run to completion" + reviewer combination)
