---
description: Turn a spec into a detailed implementation plan (the HOW), with ADR review and dual adversarial review — step 2 of spec → plan → execute.
argument-hint: "[spec-path]"
---
# Plan (plan-dc)

Turn a **behavior specification** (the *what*) into a precise **implementation plan** (the
*how*) that covers 100% of the spec, complies with the project's architectural decisions,
and passes an adversarial review by two subagents before it is considered done.

This is **step 2 of three**: `/spec-dc` (the WHAT) → `/plan-dc` (the HOW) → `/execute-dc`
(the DO). The spec is the **source of truth**. The plan exists so another developer can
implement without ambiguity, and so it can be *proven* (via traceability) that nothing in
the spec was left out.

## Non-negotiable rules

1. **Do not change the codebase.** The only artifact produced is the plan file. No code,
   migration, or config edits.
2. **The spec is the source of truth.** The plan covers exactly the spec — nothing more,
   nothing less. Do not invent requirements or scope.
3. **100% coverage.** Every functional requirement, non-functional requirement, success
   criterion, and acceptance test in the spec becomes a concrete plan item. Something may be
   deferred **only** if the **spec itself** lists it under "Constraints & Out of Scope" /
   "intentionally deferred" — and then it goes in a "Deferred (per spec)" section with a
   reference to the spec section/line.
4. **The plan reflects the current state.** No internal changelog, no "in v1 it was like
   this". When you revise during review, rewrite the file — do not accumulate history inside
   it.
5. **This is where ADRs are reviewed.** `/plan-dc` owns architectural-decision compliance
   for the whole flow (`/spec-dc` deliberately skips it). See *Decision Awareness* below.

## Input

The spec path. If the user doesn't provide one:
- If there is a single obvious `.context/specs/spec-*.md` (or the most recent one, and the
  conversation clearly points to it), use it and say which you chose.
- If ambiguous, **use the `AskUserQuestion` tool** (native structured-question tool on other harnesses) to ask which spec before continuing.

If no spec exists, **stop and tell the user** — plan a `/spec-dc` first.

## Phase 1 — Research, decisions & writing the plan

1. **Read the whole spec.** It is the source of truth for the *what*.
2. **Read the actual code.** Open every file the spec references in *Technical Context &
   Integration Points* and the relevant neighbors. Use `Grep`/`Glob`/`Read` freely; delegate
   broad sweeps to parallel `Explore` subagents. The goal: every proposed change points at
   files and structures that **exist** and follows the patterns already used in that domain.
3. **Review the decisions** (see *Decision Awareness*) — this must happen before you commit
   the plan's approach.
4. **Hold the Validation Gate** (see below) — present the approach to the user and get approval
   before committing it to a detailed plan.
5. **Write the plan** at:
   ```text
   .context/plans/plan-<unix-timestamp>-<descriptive-kebab>.md
   ```
   - `<unix-timestamp>`: `date +%s`. The filename **must** start with `plan-`.
   - `<descriptive-kebab>`: derived from the spec — ideally the same suffix as the spec, to
     pair them (e.g. spec `...-api-order-locking.md` → plan `...-api-order-locking.md`).

### Decision Awareness (ADR review — owned by this step)

Read all ADRs in `.context/decisions/` and classify:

1. **Decisions that support the plan** — reference them in the Overview / Files sections.
2. **Decisions that might conflict** — the plan's approach MUST comply, or the conflict must
   be surfaced. If a chosen approach would violate an ADR, either redesign to comply or flag
   it explicitly and fill the *Impact on Existing Decisions* table.
3. **Decisions that need updating** — record them in *Impact on Existing Decisions* and add
   the ADR update as an explicit first task in the plan.
4. **New decisions required** — architectural choices this feature introduces; record them
   in *New Decisions Required* and schedule ADR creation as a first task.

#### When a plan choice conflicts with an existing ADR

Never silently proceed. **Use the `AskUserQuestion` tool** (native structured-question tool on
other harnesses) with these options:

> "This plan would conflict with ADR-XXX: [title].
> The decision states: [brief summary]. The conflict: [what would change].
> How would you like to proceed?"
>
> 1. **Update the decision** — proceed and update the ADR with a new version
> 2. **Find alternative approach** — redesign the plan to comply, without changing the decision
> 3. **Keep current decision** — drop the conflicting part from scope
> 4. **Let Claude decide** — choose the best approach from context

**If updating a decision**, follow the repo's rule (`CLAUDE.md` → Decision Compliance): for a real
change to a decision, **create a new ADR and mark the old one `**Status:** Superseded by ADR-XXX`**
(referencing it) — do not rewrite the old ADR's decision in place. Only a minor, non-conflicting
amendment may instead bump the existing ADR's version and add a History row. Record the choice in
the plan's *Impact on Existing Decisions* table as a first plan task.

**If finding an alternative**, it must still achieve the spec's goals, not violate the ADR, and may
adjust plan scope (never the spec). The reviewer loop (Phase 2) re-checks compliance.

### Validation Gate

Before writing the detailed plan — after research and ADR review — **pause and get the user's
approval on the approach.** This prevents committing a full plan on an unclear or inconsistent
foundation.

1. Present a **3–5 line summary**: the core approach, the main files/areas it will touch, and any
   ADR impact (updates / new decisions / conflicts).
2. **Use the `AskUserQuestion` tool** (native structured-question tool on other harnesses) to ask
   whether to proceed, adjust the approach, or stop.
3. Only after the user approves, write the full plan below and run the Phase 2 review loop.

This is the *human* checkpoint; the Phase 2 dual review is the *adversarial* one — keep both.

### Snippet quality rules

When the plan includes code snippets under a change description:

- Every snippet must be **compilable as shown** — never `// ...` or pseudo-code in a snippet
  meant to be applied directly (`// rest unchanged` is fine in a context block, not an apply
  block).
- Anchor edits to a real path and line, e.g. `src/auth/login.ts:83`.
- Use **real** type/interface/function names from the codebase — no `Foo`/`Bar` placeholders.

### Mandatory plan structure

```markdown
# Implementation Plan — <Feature title>

> Source spec: `.context/specs/spec-<...>.md` (source of truth)

## Overview
- 2–4 lines: what will be built and the core approach, anchored in the codebase's existing
  patterns (cite the real integration points).

## Files to create / modify

> Path-level inventory first — one row per file — then the detail below.

| Path | Type | Description |
|------|------|-------------|
| `src/path/to/file.ext` | modify | [short description of the change] |
| `src/path/to/new.ext`  | create | [short description of the new file] |

For each file, in a subsection:
- Exact path. Create or modify.
- What changes, detailed enough to implement without guessing (responsibility, behavior,
  inputs/outputs, validations, wiring to existing services/models). Cite the real
  files/symbols it will call. Snippets follow the quality rules above.

## Tests
- Which tests to create or update, with path and the behavior each covers. Each test must
  trace to a spec requirement / acceptance test. Follow the project's existing test framework
  and patterns.

## Verification & regression
- How to confirm the changes do what they should AND don't break the existing behavior.
- Concrete regression risks (what this change could affect) and how to check them.
- Respect the project's validation practices (test/lint commands from `AGENTS.md`).

## Decisions

### Impact on Existing Decisions
<!-- Remove if no existing ADR is affected -->

| ADR | Current Decision | Proposed Change | Action |
|-----|------------------|-----------------|--------|
| ADR-XXX | [current] | [what would change] | Update/Supersede/None |

### New Decisions Required
<!-- Remove if none -->

| Decision | Context | Options to Consider |
|----------|---------|---------------------|
| [e.g. Auth strategy] | [why needed] | [Option A, B, C] |

**Note:** ADRs recorded here are created during `/execute-dc` (first wave) or via
`/add-decision` before implementation begins.

## Traceability

Table mapping EVERY spec item to the plan items that fulfill it:

| Spec item | Where fulfilled in the plan |
|---|---|
| FR-1 ... | File X, Test AT-... |
| AT-1 ... | Test ... |
| NFR ... | ... |
| Success criterion N | ... |

Every functional requirement, non-functional requirement, success criterion, and acceptance
test in the spec MUST appear in this table.

## Risks & Mitigations
<!-- Optional but recommended for non-trivial work -->

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [how to mitigate] |

## Deferred (per spec)
Only items the SPEC itself authorized deferring, each with a reference to the spec section
that authorizes it. If the spec deferred nothing, write "Nothing deferred — the spec
authorizes no deferrals.".
```

## Phase 2 — Two-reviewer parallel review loop

The point of this phase is to get two independent perspectives before calling the plan good:
one focused on architecture/traceability/ADR-compliance, one on clarity/completeness/
implementation detail. Run **at least one round**.

Each round, dispatch **both subagents in the same message** (in parallel), with **fresh**
subagents every round, using the agent definitions:

- **Reviewer Pro** (`plan-dc/reviewer-pro`) — strict senior reviewer: architecture,
  consistency, ADR-compliance, traceability, overall quality.
- **Reviewer Fast** (`plan-dc/reviewer-fast`) — quick, practical reviewer: clarity,
  completeness, implementation detail. Prefer the **Haiku** model (fast, cheap, sufficient).

Give both the same context, substituting the real paths (no literal placeholders):

```text
Review the full plan at: <PLAN PATH>.
Compare it rigorously against the spec at: <SPEC PATH>.
Also check it against the ADRs in .context/decisions/.

Evaluate:
- 100% coverage of requirements, success criteria, and acceptance tests
- Technical accuracy and consistency with the codebase
- Compliance with existing architectural decisions (ADRs); flag any conflict
- Clarity and absence of ambiguity
- Quality of the tests and verification
- Complete traceability
- Edge cases and risks

If the plan is perfect and complete, reply with ONLY the word: APPROVED.
Otherwise, give a detailed report of every gap and a suggested fix.
```

### Flow

1. Dispatch both in parallel.
2. If **both** reply exactly `APPROVED` → go to final verification.
3. If either reports gaps:
   - **Verify each finding yourself** (open the code / re-read the spec / re-read the ADR)
     before accepting it. Reviewers are wrong sometimes — don't apply a fix that doesn't hold.
   - Apply **only** the valid fixes, rewriting the plan (no changelog).
   - Start a **new round with fresh subagents**.
4. Repeat until double approval.

If after ~3 rounds the reviewers still raise gaps that you, after verifying, judge invalid
(or are taste, not coverage), stop the loop and take the open point to the user instead of
spinning forever — the rule is to converge on real coverage, not to please a reviewer.

## Final verification (after double approval)

1. Re-read the whole plan.
2. Validate 2–3 technical claims by opening the cited code files — confirm paths/symbols
   exist and the proposed change fits.
3. Re-read the spec and confirm **every** requirement and acceptance test is in the
   Traceability table. Any hole → fix it and return to Phase 2.
4. Confirm no code was changed (only the plan file exists/changed).

## Response to the user

Report the plan path and summarize what it covers (feature, main files touched, test
strategy, how many requirements/acceptance tests are traced, and any ADR impact). Do **not**
paste the whole plan into the chat.

Then **use the `AskUserQuestion` tool** (native structured-question tool on other harnesses) to
offer the next step:

> "Plan approved. Ready to implement?"
> - "Execute now" — run `/execute-dc <plan-path>`
> - "Review first" — stop so you can review the plan
> - "Edit plan" — adjust specific sections first

If the user chooses **"Execute now"**: tell them to run `/clear` and then `/execute-dc <plan-path>`
in a fresh window. **Do NOT chain into `/execute-dc` in this same session** — the context is
already full from planning, and implementing here produces worse results.

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately.
2. Explain what you're trying to do and what's blocking you.
3. **Use the `AskUserQuestion` tool** (or your harness's native structured-question tool) to ask the user how to proceed.

Never loop indefinitely.
