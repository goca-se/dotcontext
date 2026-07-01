---
description: Author a behavior specification (the WHAT) — step 1 of spec → plan → execute.
argument-hint: "[feature description]"
---
# Spec (spec-dc)

Produce a complete **behavior specification** for the feature described in $ARGUMENTS.
The goal is to describe **WHAT** the system must do — precisely enough that another
developer can implement and test it without asking follow-up questions — and **never HOW**
to build it.

This is **step 1 of three**: `/spec-dc` (the WHAT) → `/plan-dc` (the HOW) → `/execute-dc`
(the DO). The spec is the source of truth the plan is later measured against.

## Non-negotiable rules

These exist because a spec that describes implementation locks decisions in too early and
ages alongside the code; a behavior spec survives refactors.

1. **Do NOT write code.** No implementation snippets, no pseudo-code.
2. **Do NOT write an implementation plan.** No "first do X, then Y" steps — that is
   `/plan-dc`'s job.
3. **Describe observable behavior, not mechanism.** If you catch yourself writing *how*
   (class names to create, table structure, algorithm), stop and reframe as *what*
   (input → output → observable guarantee).
4. **The only artifact is the spec file.** Do not change anything else in the codebase.
5. **Do NOT review or reconcile ADRs.** Architecture decisions constrain the *how*, which
   belongs to `/plan-dc`. At most, *reference* an ADR in Technical Context if it explains an
   existing integration point — never evaluate compliance here.

## Clarity Assessment

Before asking anything, evaluate whether the request is already clear enough to write a
faithful spec. A request is **clear** when you can:

- See the connections between premises, examples, and conclusions
- Reformulate the goal in your own words without effort
- Apply the same idea to a different context
- Identify no internal "wait, there's a jump here" moment

**Decision rule:**
- If the request passes the clarity check → **proceed with zero questions** (say so briefly,
  so the user can interject).
- Otherwise → ask **only the questions that target genuine gaps** (no fixed quota).
- Never pad to hit a count; never skip a question that would actually unblock you.

**Use the `AskUserQuestion` tool** in batches of 3–4 when you ask (this is mandatory — ADR-005).
On non-Claude harnesses use your native structured-question tool (`ask_user` / `question` /
`request_user_input` / …), per the `{{ASK: <question> | <option A> | <option B> }}` convention
(ADR-018) — never degrade to plain free-text questions. If you ask zero questions, briefly tell
the user why so they can interject. Do not invent requirements to fill sections.

## Phase 1 — Research

Before writing, understand the real system. Use `Grep`, `Glob`, and `Read` extensively —
read the actual code, don't guess. The aim is for the *Technical Context* section to point
at file paths and structures that **exist**.

- Locate the modules, services, jobs, models, and routes the feature will touch.
- Understand the patterns already used in that domain (the spec should fit them).
- Note concrete paths (`app/services/.../foo_service.rb:42`) to cite later.

If research is broad, delegate parallel sweeps to `Explore` subagents (via the Task tool)
and keep only the conclusions.

### Reference materials

If the user provides or mentions visual references (images, PDFs, designs, layouts):

1. **Read/view the file** with the Read tool to understand the content.
2. **Extract key details** in text form (layout, colors, spacing, components, behavior).
3. **Record the file path** in a *Reference Materials* subsection inside Technical Context —
   visual information cannot be fully captured in text; preserve the path so `/plan-dc` and
   `/execute-dc` can consult the original.

## Phase 2 — Write the specification

Create the file at:

```
.context/specs/spec-<unix-timestamp>-<descriptive-kebab>.md
```

- `<unix-timestamp>`: Unix seconds — get it with `date +%s`. The filename **must** start
  with `spec-`.
- `<descriptive-kebab>`: a short kebab-case name derived from the request
  (e.g. `user-session-timeout`).

The spec **must** contain **all seven** sections below, in this order, each substantial
(no placeholders).

### Mandatory template

```markdown
# <Feature title>

## User Stories & Stakeholders
- Who uses, maintains, and is impacted by this feature.
- One or more stories: "As a [role], I want [goal], so that [benefit]."

## Success Criteria
- Measurable, observable criteria that define "done".
- Each verifiable — no "improved"/"better"/"faster" without a number or observable condition.
- Cover functional success (it works) AND operational success (it works well).

## Functional Requirements
- What the system MUST do — the core behaviors.
- Inputs, outputs, and expected transformations.
- Happy path, edge cases, AND error conditions.
- Specific enough to implement without asking.

## Non-Functional Requirements
- Performance (latency, throughput, resource use), reliability, security, concurrency/scale.
- Include only what is genuinely relevant — no boilerplate.

## Constraints & Out of Scope
- What this feature explicitly does NOT include.
- Boundaries that must not be crossed.
- Intentionally deferred design decisions — list each one.
- WARNING: anything NOT listed here is IN scope and MUST be covered by the Functional
  Requirements and Acceptance Tests.

## Technical Context & Integration Points
- Existing modules, files, and systems the feature interacts with.
- APIs, data structures, protocols involved.
- External service/library dependencies.
- Cite real file paths and structures from the codebase.
- (Optional) Reference Materials subsection with paths to any visual references.

## Acceptance Tests
- Concrete, executable scenarios (Given/When/Then or equivalent).
- Cover happy path, edge cases, error paths, and boundaries.
- Each test maps to one or more Functional Requirements.
- BEHAVIORAL descriptions, not code — say what to verify, not how.
```

### Notes on the sections

- **Success Criteria vs Functional Requirements:** criteria are the "are we done?" ruler;
  requirements are the behaviors that deliver it. Don't repeat one in the other.
- **Constraints & Out of Scope is the section most often wrong by omission.** It defines the
  boundary: whatever you fail to list here becomes an obligation covered by the requirements
  and tests. Be explicit about what is deferred.
- **Acceptance Tests** must be concrete enough that someone could write the automated test
  from them — but must not contain the test code.

## Phase 3 — Final verification

After writing, re-read the file and confirm:

1. All seven sections present and substantial (none empty/placeholder).
2. Open 2–3 files cited in *Technical Context* and confirm the paths/structures really
   exist. Fix anything wrong.
3. The Acceptance Tests are concrete and cover the stated Functional Requirements (every
   relevant requirement has at least one scenario).
4. No section describes implementation ("how"). If any does, reframe it.

Fix any problem before finishing.

## Response to the user

Report the spec file path and give a short summary of what it covers (the feature, the main
requirements, and what was left out of scope). Do **not** paste the whole spec into the chat.

Then **use the `AskUserQuestion` tool** (native structured-question tool on other harnesses) to
offer the next step:

> "Spec written. Ready to plan the implementation?"
> - "Plan now" — run `/plan-dc <spec-path>`
> - "Review first" — stop so you can review the spec before planning
> - "Edit spec" — adjust specific sections first

If the user chooses **"Plan now"**: tell them to run `/clear` and then `/plan-dc <spec-path>` in a
fresh window. **Do NOT chain into `/plan-dc` in this same session** — the context is already full
from writing the spec, and continuing here produces a worse plan.

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately.
2. Explain what you're trying to do and what's blocking you.
3. **Use the `AskUserQuestion` tool** (or your harness's native structured-question tool) to ask the user how to proceed.

Never loop indefinitely.
