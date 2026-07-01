---
description: Implement an approved plan end-to-end in parallel waves, with tests and dual review — step 3 of spec → plan → execute.
argument-hint: "[plan-path]"
---
# Execute (execute-dc)

Take an already-written **implementation plan** (the *how*) and **implement it**, with safe
parallelism and adversarial review at the end.

This closes the trio: `/spec-dc` (the WHAT) → `/plan-dc` (the HOW) → **`/execute-dc`** (the
DO).

The **plan is the contract**: implement 100% of what it specifies. Do not defer, skip, or
mark as "future work" anything the plan itself did not list under "Deferred" / "Out of
Scope".

## Non-negotiable rules

1. **Implement the whole plan** — don't ask whether to implement everything; the request to
   execute the plan is the authorization. The only thing left out is what the plan marked
   deferred/out of scope.
2. **Do not modify the plan file.** It is the contract; if something in it is wrong, point it
   out to the user — don't silently rewrite it. (Report progress in chat, not by editing the
   plan.)
3. **Run tests after each wave** and at the end. Don't advance on a broken wave.
4. **Don't skip the final review loop.** Always at least one round with two fresh reviewers.
5. **Commit/push only when the user asks.** Creating the work branch is OK; committing,
   pushing, or opening a PR happens only on explicit request. For any hosting-CLI action,
   detect the platform first (see `.claude/skills/git-platform/SKILL.md`).

## Before starting

**Check Reference Materials** in the plan and its source spec:
- If files are listed (images, PDFs, layouts), **read/view each** before proceeding.
- If a referenced file is missing or inaccessible, ask the user for it.

**ADR compliance:** `/plan-dc` already reviewed the architectural decisions and recorded any
impact. Here, simply implement in line with that. If, mid-implementation, you hit a conflict with
an ADR that the plan did **not** anticipate, **stop and use the `AskUserQuestion` tool** (native
structured-question tool on other harnesses) with the same four options `/plan-dc` uses — **Update
the decision** / **Find alternative approach** / **Keep current decision** / **Let Claude decide** —
rather than deciding silently. If the user picks *Update*, apply the ADR mechanics (bump
`**Version:**`, add a History row, mark the old one `Superseded by ADR-XXX` if fully replaced).

## Step 0 — Git hygiene (before anything else)

Before reading or implementing anything:

1. Confirm the working tree is clean. If there are uncommitted changes unrelated to the plan,
   **stop and tell the user** (don't discard their work).
2. Start from the repository's **base branch**, updated. Detect it rather than assuming —
   e.g. `git symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/`), falling
   back to the current branch; common bases are `main` or `develop`. Follow the repo's
   convention: `git checkout <base>` and `git pull`.
3. Create a work branch from the base, named after the plan (e.g. `feature/<plan-slug>`). All
   implementation happens on it.

This guarantees the implementation is born in sync with the base and never commits directly
to the default branch.

### Worktree isolation (optional)

**Use the `AskUserQuestion` tool** (native structured-question tool on other harnesses) to offer
an isolated git worktree so the user can work on other tasks without stashing:

> "Create an isolated worktree for this work?"

Determine the type from the plan content: `feature/`, `bugfix/`, `hotfix/`, `chore/`,
`experiment/`. If the user accepts:

```bash
PROJECT_NAME=$(basename "$(pwd)")
git worktree add ../${PROJECT_NAME}-<plan-slug> -b <type>/<plan-slug>
```

Then tell the user how to `cd` into it and how to `git worktree remove` it when done. If the
user declines, proceed on the work branch in the current workspace.

## Step 1 — Read the plan

Read **the entire plan file** (`.context/plans/plan-*.md`). If the user didn't say which,
use the most recent/obvious one and say which you chose; if ambiguous, ask.

If the file doesn't exist, **warn and stop** — no plan, no contract.

Also record the plan's **Deferred / Out of Scope** section: it is the only boundary of what
may be left out.

## Step 2 — Decompose into waves

Break the plan into **waves** of parallelizable work.

- **Path A — the plan already has explicit waves/phases** (`## Wave`, `## Phase`, `## Step`,
  numbered phases): use them directly.
- **Path B — no explicit waves:**
  1. List every discrete change in the plan.
  2. For each, identify the files it touches.
  3. Build a dependency graph:
     - Same file touched → dependency (serialize).
     - Explicit ordering in the plan → dependency.
     - Otherwise → independent.
  4. Topologically sort: Wave 1 = no dependencies; Wave 2 = depends only on Wave 1; etc.

When in doubt, **add a dependency** (serialize). Parallelism that causes a file conflict costs
more than one extra wave. The core guarantee: **within a wave, no task touches the same file
as another** — that is what makes parallel execution safe without separate worktrees.

## Step 3 — Report the execution plan (before executing)

Show the user, without touching code yet:
- How many waves.
- How many tasks per wave.
- Which files each task touches.
- The dependencies between tasks.
- **Coverage:** confirm every actionable plan item maps to some task (or is in Deferred). If
  something in the plan fits no task, that's a hole — resolve it before executing.

## Step 4 — Execute wave by wave

For each wave, in order:

1. Dispatch the wave's tasks as **parallel subagents (up to 3 at a time)** — in the same
   message, so they run together (via the Task tool). Give each subagent: the slice of the
   plan it implements, the files it may touch, and the instruction to follow the codebase
   patterns (don't invent new structure).
2. Because the wave guarantees disjoint files between tasks, parallel execution on the same
   working tree is safe. If, while detailing, two tasks in a wave end up touching the same
   file, **serialize them** (or move one to the next wave).
3. When the wave finishes, **run the tests relevant to that change** and fix failures before
   moving on. Use the **project's own** test command (Makefile / `AGENTS.md` / `CLAUDE.md`),
   not a generic one.
4. Only advance to the next wave when the current one is green.

On flaky suites: if the project has known flakiness, run the tests **focused** on the changed
area and don't treat pre-existing/flaky failures as your regression — but state clearly in
the report what ran and what was skipped.

## Step 5 — Final review loop

After all waves:

1. Run the test suite (full when viable; focused + a note when the suite is flaky) and fix
   failures.
2. Dispatch **two fresh reviewers in parallel**, comparing the implementation to the plan via
   `git diff`, using the agent definitions:
   - **Reviewer Pro** (`execute-dc/reviewer-pro`) — strict: quality, architecture, fidelity
     to the plan (implemented 100%? followed the patterns? covered the acceptance tests?).
   - **Reviewer Fast** (`execute-dc/reviewer-fast`) — quick: practical details, clarity,
     completeness. Prefer the **Haiku** model.
   Both reply `APPROVED` if faithful and complete, or a report of gaps.
3. If **both** approve → final verification. If there are gaps: **verify each finding
   yourself** (reviewers err too), apply only the valid ones, and run a **new round with fresh
   subagents**.

If after ~3 rounds the reviewers only raise gaps you judge (after verifying) invalid or
taste-based (not fidelity to the plan), stop and take the open point to the user — the ruler
is implementing the plan, not pleasing a reviewer.

## Final verification

1. Review the whole `git diff` manually — confirm it matches the plan and there's no leftover
   (dead code, forgotten file, unplanned TODO).
2. Run the tests again.
3. Re-confirm coverage: every actionable plan item is implemented (or in Deferred).
4. Summarize to the user what was implemented (files created/changed, tests, test status) and
   the branch it's on. Don't commit/push unless asked.

## Closing the loop (knowledge reconciliation — deferred)

A completed plan usually changes the living context: new entities, changed flows, new
conventions, decisions actually taken. Reconciling those back into `.context/CONTEXT.md`, the
ADRs, and the skills keeps the context from drifting behind the code (ADR-019).

Until a dedicated `/sync-context` command ships, do this **manually and only if the user
agrees**: point out which documented areas the change affects and offer to update them via
`/setup-context` (CONTEXT.md), `/add-decision` (ADRs recorded in the plan's *New Decisions
Required*), and `/add-skill` (new reusable patterns). Never rewrite canonical files silently.

## If Something Fails

1. Stop immediately. 2. Analyze the error. 3. Fix before continuing. 4. Never accumulate
errors. 5. Tell the user what went wrong and what was fixed.

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately.
2. Explain what you're trying to do and what's blocking you.
3. **Use the `AskUserQuestion` tool** (or your harness's native structured-question tool) to ask the user how to proceed.

Never loop indefinitely.
