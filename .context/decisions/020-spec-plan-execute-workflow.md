# ADR-020: Spec → Plan → Execute Feature Workflow

**Status:** Accepted
**Date:** 2026-07-01
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

Feature development used a single-shot PRP flow: `/generate-prp` planned the *what* and the
*how* in one artifact (running the clarity assessment, reviewing ADRs, and producing an
implementation plan with phases), and `/execute-prp` implemented it (ADR-004, ADR-018).

Two structural weaknesses:

1. **WHAT and HOW were coupled in one document, reviewed once.** Behavior and implementation
   were decided together, so architectural decisions were locked in at plan time and the
   plan aged alongside the code. There was no independent, adversarial check that the plan
   actually covered everything or that the implementation was faithful to it.
2. **ADR review happened at `/generate-prp` time** — i.e. while still deciding *what* the
   feature should do. Architecture constraints belong to *how* you build, not *what* the
   feature must do.

Gocase's internal **Spec-Driven Development** practice (the `spec-author` → `plan-author` →
`plan-executor` skills) separates these concerns cleanly:

- **spec** = the WHAT — a behavior contract (observable behavior, no implementation, no ADRs).
- **plan** = the HOW — files/tests/verification + a 100% traceability table + ADR review,
  hardened by a dual adversarial review loop.
- **execute** = the DO — parallel waves, tests per wave, dual review of the diff vs the plan.

We adopt this model as dotcontext's feature workflow, folding in the dotcontext features
worth keeping rather than replacing the toolkit wholesale.

## Decision

### 1. Three commands replace the PRP pair

`/spec-dc` (WHAT) → `/plan-dc` (HOW) → `/execute-dc` (DO). Artifacts are **versioned**
source-of-truth files (committed, like ADRs — not per-session/gitignored):

- `.context/specs/spec-<unix-timestamp>-<kebab-slug>.md`
- `.context/plans/plan-<unix-timestamp>-<kebab-slug>.md`

The plan pairs with its spec by suffix, and the executor treats the plan as the contract.

### 2. ADR review moves from spec to plan

`/spec-dc` **must not** evaluate ADR compliance — a behavior spec is architecture-agnostic;
it may only *reference* an ADR to explain an existing integration point. `/plan-dc` **owns**
ADR review for the whole flow: it reads `.context/decisions/`, records impact in the plan's
*Impact on Existing Decisions* / *New Decisions Required* tables, and surfaces conflicts per
the `AGENTS.md` compliance rule (proceed & update the ADR / comply / cancel). `/execute-dc`
only surfaces an ADR conflict the plan did not anticipate.

### 3. Dual adversarial review at the spec, plan, and execute boundaries

**All three** commands end with a review loop that dispatches **two fresh subagents in parallel**
each round until both reply `APPROVED`:

- **Reviewer Pro** — strict (structure/scope/grounding/fidelity at spec; architecture/consistency/
  ADR-compliance/traceability at plan & execute).
- **Reviewer Fast** — quick (clarity, completeness, testability/detail; prefers the Haiku model).

The orchestrator verifies each finding itself before applying it, and caps at ~3 rounds before
escalating an open point to the user (converge on substance, not reviewer taste). The reviewers
are extracted as agent files (ADR-012): `spec-dc/`, `plan-dc/`, and `execute-dc/`
`{reviewer-pro,reviewer-fast}`.

**The spec review is deliberately narrower in scope.** The source workshop had *no* spec review;
we add one because a bad spec poisons everything downstream (a plan can be 100% faithful to a
*wrong* spec, and the plan review would never catch it). But the spec is the first artifact —
there is no upstream artifact to measure it against — so its review judges only **well-formedness,
testability, scope hygiene, internal consistency, grounding (cited paths exist), and faithfulness
to the original request**, and is **forbidden from judging product merit or inventing
requirements**. Whether the feature is the *right thing to build* stays a human call (the "Review
first" checkpoint and the clarity assessment). This keeps the loop from bikeshedding a macro idea.

### 4. dotcontext strengths are preserved (not a wholesale replacement)

- `/spec-dc` keeps the **clarity assessment** (ask only the questions that unblock) and
  **reference-material handling** from `generate-prp`.
- `/plan-dc` keeps the **Affected-files table**, **snippet quality rules**, and **Risks**, plus
  two behaviors moved here from the PRP flow: the **Validation Gate** (a user-approval checkpoint
  on the approach *before* the detailed plan is written) and the **four-option ADR-conflict
  resolution** (Update / Find alternative / Keep / Let Claude decide) with the ADR
  version/History/Supersede mechanics.
- `/execute-dc` keeps **worktree isolation**, but detects the repo's **base branch** instead
  of hardcoding `develop`; it re-uses the same four-option flow for a conflict the plan didn't
  anticipate.
- **`AskUserQuestion` is mandatory (ADR-005)** and stays the explicit primary tool in all three
  commands — never degraded to free text. On non-Claude harnesses it renders to the native
  structured-question tool via the `{{ASK}}` convention (ADR-018). Registered in
  `DOTCONTEXT_COMMANDS`; documented in the `AGENTS.md` `## Workflows` section for
  Gemini/Cursor/Codex.

### 5. The plan is an immutable contract

`/execute-dc` does **not** edit the plan file (unlike `execute-prp`, which marked checkboxes)
— if the plan is wrong, it surfaces that to the user rather than rewriting it silently.
Progress is reported in chat. The only thing left unimplemented is what the plan itself lists
under Deferred / Out of Scope.

### 6. Retire the old flow non-destructively

`generate-prp`, `execute-prp`, and the `.context/prp/` template tree are removed from the
toolkit and from fresh `init`. On `dotcontext update` they are simply **dropped from the
managed set** — existing projects keep their local command files and `.context/prp/`
untouched (they freeze but keep working), honoring safe-by-default updates (ADR-003). New
projects get the trio only. This satisfies "retire and replace" without breaking any current
install.

To actually **deliver** the trio to existing installs, `update` (a) adds the new Claude
commands + reviewer agents via the managed-template set, (b) re-runs `emit_agent_commands`
(create-only) for the per-harness dirs it finds (`.opencode/command`, `.github/prompts`) so
opencode/Copilot pick them up, and (c) prints a migration notice. `AGENTS.md` is a create-only
seed, so its `## Workflows` table is **not** auto-rewritten — the notice tells Gemini/Cursor/
Codex users to refresh it (or re-run `init`).

### 7. Knowledge reconciliation is deferred

`/sync-context` (ADR-019) is not implemented here. `/execute-dc` references reconciliation as
a manual/future final step (update `CONTEXT.md` via `/setup-context`, ADRs via
`/add-decision`, skills via `/add-skill`) and never rewrites canonical files silently.

## Consequences

### Positive
- Separation of concerns: behavior decided independently of implementation; ADR review lands
  where architecture is actually chosen.
- Coverage is **provable** via the plan's traceability table, and fidelity is enforced by the
  execute-time review against the plan.
- Two independent adversarial reviews (plan and execution) catch gaps a single pass misses.
- Fully portable across the six harnesses; non-breaking for existing installs.

### Negative
- Three commands instead of two — more ceremony for a small feature (mitigated: for tiny
  changes, `/fix-bug` or a direct edit is still the right tool; the trio is for real features).
- Two artifacts (spec + plan) to keep in sync with the code until reconciliation (ADR-019)
  ships.
- Dropping in-plan checkbox progress-tracking loses that lightweight status UX (mitigated:
  the executor reports wave-by-wave progress in chat).

## Alternatives Considered

1. **Keep the single-shot PRP flow** — rejected: couples WHAT + HOW and reviews ADRs too
   early; no independent coverage/fidelity check.
2. **Adopt the Gocase skills verbatim as auto-discoverable `SKILL.md`** — rejected: they are
   side-effecting *actions* (write files, dispatch agents, run tests, create branches), which
   ADR-018 classifies as **commands** (explicit-only), not auto-invocable skills.
3. **Keep both flows in parallel** — rejected: two methodologies to maintain and document;
   the decision is to standardize on one.
4. **Leave ADR review in the spec step** — rejected: a behavior spec must be
   architecture-agnostic; ADR compliance belongs to the plan (the *how*).

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07-01 | Initial decision — spec/plan/execute trio, ADR review in plan, dual reviewers, non-destructive retire of the PRP flow |
| 1.1 | 2026-07-07 | Added a dual review loop to `/spec-dc` (scoped to well-formedness/fidelity, never product merit) after tech-lead review — the workshop had none |
| 1.2 | 2026-07-17 | `/spec-dc` writes the spec in the **language of the original request** (Portuguese request → Portuguese spec; defaults to the repo's primary language, then English). Prose only — the seven section headings and the filename slug stay ASCII structural anchors `/plan-dc` relies on. `/plan-dc` and `/execute-dc` are unchanged (English) |

## Related
- ADR-004: Claude Code Integration via Slash Commands — this supersedes the PRP pair as the feature-development flow
- ADR-005: Mandatory structured-question tool — clarity assessment + `{{ASK}}` used by all three commands
- ADR-009: Multi-Agent Orchestration — the dual reviewers and parallel waves follow this pattern
- ADR-012: Agent File Extraction — the four reviewers ship as extracted agent files
- ADR-018: Command Portability & Invocation Modes — **amends** its command list (adds spec-dc/plan-dc/execute-dc, retires generate-prp/execute-prp)
- ADR-019: Knowledge Reconciliation after PRP — deferred; `/execute-dc` references it and its command references are updated to the trio
- Inspired by Gocase's Spec-Driven Development skills (`spec-author` → `plan-author` → `plan-executor`)
