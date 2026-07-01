# ADR-019: Knowledge Reconciliation after PRP execution

**Status:** Proposed
**Date:** 2026-06-24
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

> **Note (2026-07-01, ADR-020):** the PRP flow this ADR was written against has been replaced
> by the `spec-dc` → `plan-dc` → `execute-dc` trio. Command/artifact references below are
> updated accordingly (`generate-prp` → `plan-dc`; `execute-prp` → `execute-dc`; the
> planning artifact is now `.context/plans/plan-*.md`). This proposal remains **deferred**:
> `/sync-context` is not yet implemented, and `/execute-dc` references reconciliation only as
> a manual final step.

## Context

dotcontext reads its living knowledge before acting: `/plan-dc` and `/execute-dc`
consult `.context/decisions/` (ADRs), `.claude/skills/`, and patterns in the codebase.
But the loop is **one-directional** — nothing writes verified outcomes back. When
`/execute-dc` finishes (its "When Finished" step only runs test/lint), the PRP is left in
`.context/prp/generated/` as a dead historical file. The knowledge it actually produced —
new entities, changed flows, new conventions, decisions actually taken — never lands in
`CONTEXT.md`, the ADRs, or the skills. Over time the living context drifts behind the code,
which is the exact failure dotcontext exists to prevent.

The `/execute-dc` Decision Compliance Check already writes *one* kind of feedback: it
versions/supersedes an ADR when a conflict is hit mid-implementation. That proves the
write-back pattern is acceptable — it is just incomplete and triggered only by conflict,
not by completion.

This idea is borrowed from OpenSpec's `/opsx:archive`, which folds a change's delta back
into its living spec. We adopt the **loop-closing** behavior, not the living-spec
machinery — dotcontext already has living sources to feed (`CONTEXT.md` + ADRs + skills).

## Decision

### 1. A reconciliation step closes the loop

Knowledge reconciliation becomes the final, sequential act of a completed PRP. It writes
verified outcomes back into the **existing** living sources — `CONTEXT.md`, ADRs, skills —
never into a new spec artifact. dotcontext stays a context toolkit; it does **not** become
spec-driven.

### 2. `/sync-context` command (primary), invoked by `/execute-dc`

Ship reconciliation as a standalone `/sync-context [prp-file]` command — an *action*
runnable anytime, also useful to reconcile out-of-band/manual changes — and have
`/execute-dc`'s final e2e phase invoke it once all success criteria pass. Standalone keeps
it composable and portable (rendered per harness via the `AGENTS.md` workflow table,
ADR-018); auto-invocation keeps it from being forgotten. This respects "actions, not
phases": sync is something you *can* do anytime, the flow merely nudges it.

### 3. The PRP pre-declares the delta — `Context Impact` section

`/plan-dc` gains a `Context Impact` section in the PRP template, mirroring the existing
`Impact on Existing Decisions` ADR table. It declares, at plan time, what each documented
area gains/changes/loses:

```markdown
| Area (CONTEXT.md section / ADR / skill) | Change | Detail |
|-----------------------------------------|--------|--------|
| Core Entities                           | MODIFIED | ... |
| Main Flows                              | ADDED    | ... |
```

Reconciliation then **applies a declared delta** instead of re-deriving it — cheap,
reviewable, and consistent with the ADR-impact pattern the user already knows.

### 4. Safe by default

Reconciliation never silently rewrites canonical files. It presents the proposed
`CONTEXT.md`/ADR edits as a diff and confirms via the native structured-question tool
(ADR-005) before writing — the same contract as `dotcontext update` (ADR-003). ADRs planned
in the PRP's *New Decisions Required* table are created here (status Accepted), the
`decisions/README.md` index is updated, and superseded ADRs are linked.

### 5. Reuses existing writers — no new engine

`CONTEXT.md` edits reuse the section-writing logic already in `/setup-context`; ADR creation
reuses `/add-decision`; skill promotion reuses `/add-skill`. No new schema engine, no new
file format — pure Markdown + the single bash executable (ADR-001).

## Consequences

### Positive
- Living context stays in sync with the code — the drift dotcontext fights is actually closed.
- Decisions become persistent automatically, not only when a conflict forces it.
- `Context Impact` makes reconciliation mechanical and reviewable.
- Works across all six harnesses via command portability (ADR-018).

### Negative
- One more confirmation gate at the end of a PRP (mitigated: single batched diff; skippable when `Context Impact` is "none").
- `Context Impact` adds a section to fill at plan time (mitigated: optional — write "none" when nothing documented changes).
- Auto-invocation from `execute-prp` runs in a possibly-full context window; for large PRPs the standalone `/sync-context` in a fresh context is recommended (noted in the command).

## Alternatives Considered

1. **Adopt a living spec like OpenSpec (`specs/` + delta + archive)** — rejected: replaces
   dotcontext's philosophy; `CONTEXT.md` + ADRs already are the living sources.
2. **Reconcile only ADRs, keep `CONTEXT.md` manual** — rejected: `CONTEXT.md` is the largest
   drift surface.
3. **Fully automatic reconciliation, no confirm** — rejected: violates safe-by-default (ADR-003).
4. **Phase-only inside `execute-prp`, no standalone command** — rejected: can't reconcile
   out-of-band changes and isn't re-runnable.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-24 | Initial proposal (knowledge reconciliation, /sync-context, Context Impact) |

## Related
- ADR-003: Safe Update Behavior — reconciliation reuses the diff-then-confirm contract
- ADR-005: Mandatory structured-question tool — used at the reconciliation gate
- ADR-009: Multi-Agent Orchestration — reconciliation may dispatch a doc-writer subagent
- ADR-018: Command portability — `/sync-context` renders to each harness's native invocation
- Inspired by OpenSpec `/opsx:archive` (fold change delta into the living source)
