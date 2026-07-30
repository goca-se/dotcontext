---
description: Author a lean behavior spec (the WHAT) — fast path with one review pass. Step 1 of spec → plan → execute.
argument-hint: "[feature description]"
---
# Spec Quick (spec-quick)

Write a **behavior specification** for the feature in $ARGUMENTS — the **WHAT**, never the HOW —
in a single pass.

This is the fast path variant of `/spec-dc`: same artifact location, same section names, same
downstream contract with `/plan-dc`, but with **bounded research, conditional sections, and at
most one review pass**.

- Use **`/spec-quick`** when the request is already clear, or the feature is small to medium.
- Use **`/spec-dc`** when the feature is large or risky, or the spec will be read by people who
  weren't part of this conversation.

## Rules

1. **No code**, no pseudo-code, no implementation plan — the plan is `/plan-dc`'s job.
2. **Observable behavior only:** input → output → guarantee. If you're naming classes, tables,
   or algorithms, you drifted into HOW — reframe it as WHAT.
3. **The spec file is the only artifact.** Change nothing else in the codebase.
4. **Do not evaluate ADR compliance** (ADR-020 §2 — that belongs to `/plan-dc`). You may
   *reference* an ADR to explain an existing integration point.
5. **Never invent requirements to fill a section.** Omitting an optional section beats padding
   it — padding is what makes a spec slow to write and slow to review.

## Step 1 — Clarify (at most one batch)

Run the clarity assessment: can you restate the goal in your own words, with no internal "wait,
there's a jump here" moment?

- **Clear** → ask **zero questions**. Say so in one line so the user can interject, and continue.
- **Not clear** → **one** `AskUserQuestion` batch (3–4 questions) covering only what actually
  blocks you. On non-Claude harnesses use the native structured-question tool per the
  `{{ASK: <question> | <option A> | <option B> }}` convention (ADR-018) — never plain free text.

There is no second batch. Anything still open afterwards goes into *Constraints & Out of Scope*
as an explicit assumption, and you move on.

## Step 2 — Bounded research

Budget: **one** `Explore` subagent **or** up to ~5 targeted `Grep`/`Glob`/`Read` calls. Stop as
soon as you can name the integration points the feature actually touches — not when you
understand the whole codebase.

Cite concrete paths (`app/services/foo_service.rb:42`) **only** for points the feature touches,
and **never cite a path you haven't opened**.

If the user provides visual references (images, PDFs, designs): read them, extract the details in
text, and record the file path under *Reference Materials* inside Technical Context — visual
information can't be fully captured in prose, so the path must survive for `/plan-dc`.

## Step 3 — Write the spec

Get the timestamp with `date +%s`, then create:

```text
.context/specs/spec-<unix-timestamp>-<descriptive-kebab>.md
```

The filename **must** start with `spec-`, and `<descriptive-kebab>` is ASCII kebab-case with no
accents.

**Language:** write the prose in the language of the request (a Portuguese request produces a
Portuguese spec), falling back to the language of the Q&A, then the repository's primary
language, then English. Keep the **section headings exactly as written below, in English** — they
are structural anchors `/plan-dc` relies on.

### Required sections

```markdown
# <Feature title>

## User Stories & Stakeholders
- Who uses and maintains this. One or more: "As a [role], I want [goal], so that [benefit]."

## Functional Requirements
- What the system MUST do: inputs, outputs, transformations.
- Happy path, edge cases, AND error conditions.
- Specific enough to implement without a follow-up question.

## Constraints & Out of Scope
- What this explicitly does NOT include, and boundaries that must not be crossed.
- Each intentionally deferred decision, and each assumption you carried over from Step 1.
- WARNING: anything NOT listed here is IN scope and MUST appear in the requirements and tests.

## Technical Context & Integration Points
- Existing modules, files, APIs, and data structures the feature interacts with.
- Real paths you opened in Step 2. External dependencies.
- (Optional) Reference Materials subsection with paths to visual references.

## Acceptance Tests
- Concrete scenarios (Given/When/Then or equivalent), behavioral — not test code.
- Happy path, edge cases, error paths, boundaries.
- Every Functional Requirement maps to at least one test.
```

### Optional sections — emit only when they carry real content

- `## Success Criteria` — only for measurable outcomes that an acceptance test doesn't already
  express (a latency budget, an error-rate ceiling, an adoption number). If every criterion would
  just restate a test, skip the section.
- `## Non-Functional Requirements` — only when performance, reliability, security, or concurrency
  genuinely constrain the behavior. Skip it for a plain CRUD or UI change.

When you emit them, use those exact headings and place them after *User Stories & Stakeholders*
and *Functional Requirements* respectively, so the order matches `/spec-dc`.

## Step 4 — One review pass (conditional)

**Skip the review entirely** when the spec is small: **≤3 functional requirements AND** no
integration with existing code beyond the paths you opened in Step 2. Say in chat that you
skipped it and why.

Otherwise dispatch **one** `spec-dc/reviewer-pro` subagent (Task tool), substituting real values:

```text
Review the behavior spec at: <SPEC PATH>.
The original request (the yardstick) was: <ORIGINAL REQUEST + clarifying Q&A>.

Apply your agent definition's checklist. This spec came from /spec-quick: `Success Criteria` and
`Non-Functional Requirements` are OPTIONAL there — their absence is NOT a defect. The spec is
expected to be in the request's language; a non-English spec is not a defect, but a spec in the
wrong language is.

Reply with ONLY the word APPROVED, or list each defect with its section / file:path / request
line and a concrete fix.
```

**Verify each finding yourself**, apply the valid ones, and **stop — there is no second round.**
Reject any "gap" that is really new product scope the request never asked for. If a finding is
real but needs a product call, take it to the user instead of guessing.

## Step 5 — Mechanical check

Cheap, no full re-read:

```bash
grep -n '^## ' <SPEC PATH>
```

Confirm the five required headings are present and in order, and that no section slid into HOW.
Don't re-verify what the reviewer already verified.

## Report

Print the spec path and a 3–5 line summary (the feature, the main requirements, what's out of
scope). Do **not** paste the spec into chat. Then:

> Next: run `/clear`, then `/plan-dc <spec-path>`

Do **not** chain into `/plan-dc` in this session — the context is already full from writing the
spec, and a fresh window produces a better plan. No closing menu: if the user wants changes,
they'll say so.

## If You Get Stuck

Three failed attempts at the same step → stop, explain what's blocking you, and ask how to
proceed with `AskUserQuestion` (or the harness's native structured-question tool). Never loop
indefinitely.
