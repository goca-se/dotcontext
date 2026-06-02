# Generate PRP

Generate a PRP (Product Requirements Prompt) for the feature described in $ARGUMENTS.

## Process

1. **Read the request** in $ARGUMENTS
2. **Clarity assessment** (see below) — ask only the N questions needed (0..N)
3. **Analyze the codebase** to understand existing patterns and gather real file/line references
4. **Consult relevant skills** in `.claude/skills/`
5. **Check decisions** in `.context/decisions/` — identify any that might be affected
6. **Fill Problem / Scope / Decisions sections** of the PRP using the template at `.context/prp/templates/feature.md`
7. **Validation Gate** — pause, summarize, run auto-validation subagent
8. **Fill Implementation Plan + Parallelism Map** after user approval
9. **Save** the PRP

## Clarity Assessment (replaces mandatory N-questions quota)

Before asking anything, evaluate whether the request is already clear enough to generate a faithful PRP. A request is **clear** when you can:

- See the connections between premises, examples, and conclusions
- Reformulate the goal in your own words without effort
- Apply the same idea to a different context
- Identify no internal "wait, there's a jump here" moment

Clarity is a state of structural visibility — it does not guarantee truth, only intelligibility.

**Decision rule:**
- If the request passes the clarity check → **proceed with zero questions**
- Otherwise → ask **only the questions that target genuine gaps** (no fixed quota; could be 1, could be 7)
- Never pad to hit a count; never skip a question that would actually unblock you

Use the AskUserQuestion tool in batches of 3–4 when you do ask. If you decide to ask zero questions, briefly tell the user why ("The request is clear — proceeding to PRP.") so they have a chance to interject.

## Decision Awareness

Read all ADRs in `.context/decisions/` and identify:

1. **Decisions that support the feature** — Reference them in Technical Design
2. **Decisions that might conflict** — Flag them in Risks section
3. **Decisions that need updating** — Add to Implementation Plan Phase 1 as explicit task
4. **New decisions required** — Architectural choices this feature will introduce

### Existing Decisions Impact

If the feature would require changing an existing decision, fill the **Impact on Existing Decisions** table in the PRP:

```markdown
| ADR | Current Decision | Proposed Change | Action |
|-----|------------------|-----------------|--------|
| ADR-XXX | [current] | [what would change] | Update/Supersede |
```

### New Decisions Required

If the feature requires significant architectural choices, fill the **New Decisions Required** table and add ADR creation as Phase 1 tasks:

```markdown
### Phase 1: Setup & Decisions

1. [ ] Create ADR-XXX: [Decision title]
2. [ ] Create ADR-YYY: [Decision title]
3. [ ] [Other setup tasks...]
```

## Snippet Quality Rules

When the PRP includes code snippets under **Technical Design**:

- Every snippet must be **compilable as shown**. Never use `// ...` or pseudo-code inside a snippet meant to be applied directly. (`// rest unchanged` is OK in context blocks, not in apply blocks.)
- When modifying existing code, anchor the change to a real path and line, e.g. `src/auth/login.ts:83`.
- Use **real type, interface, and function names** from the codebase. No `Foo`, `Bar`, `MyHandler` placeholders.
- The **Affected files** table must be path-level: one row per file with `path | type (create/modify) | description`.

## Validation Gate

After filling **Summary / Context / Scope / Technical Design / Decisions** — but **before** generating the Implementation Plan — pause and:

1. Show the user a 3–5 line summary of Problem + Scope + Decisions
2. Launch the auto-validation subagent (next section) **in parallel**
3. Wait for both the user response and the subagent report
4. Only after user approval (and any subagent findings addressed) fill in **Implementation Plan + Parallelism Map**

This prevents committing to an implementation plan against an unclear or inconsistent foundation.

## Auto-validation Subagent (parallel, Haiku)

At the Validation Gate, dispatch one subagent via the Task tool. Prefer the **Haiku 4.5 model** (fast, cheap, sufficient for a checklist pass).

Subagent type: `general-purpose` (or `Explore` if read-only is enough).

Prompt the subagent to verify the PRP draft so far:

- Every file referenced in the **Affected files** table exists at the given path (or is explicitly marked `create`)
- Every `path:line` reference in snippets resolves to a real line in the current code
- Snippets compile against the project's actual library versions (check `package.json` / `Cargo.toml` / etc.)
- **Acceptance criteria** are objectively verifiable (no "works well", "is fast" — must be testable)
- **What changes** and **What doesn't change** are mutually exclusive — nothing appears in both, no ambiguous item

The subagent returns a short report (under 250 words) with: ✓ passed checks, ✗ failed checks with file/line evidence. Address ✗ findings before proceeding.

## Reference Material Handling

If the user provides or mentions visual references (images, PDFs, designs, layouts):

1. **Read/view the file** using the Read tool to understand the content
2. **Extract key details** in text form (layout structure, colors, spacing, components, behavior)
3. **Document the file path** in a "Reference Materials" subsection inside Technical Design
4. **Add explicit task** in Phase 1: "Review reference materials before implementing"

Visual information cannot be fully captured in text — always preserve file paths so the executor can consult the originals.

## Output

Save the generated PRP at `.context/prp/generated/YYYYMMDD-[feature-slug].md` (today's date, URL-friendly slug).

## After Generating

Show the user:

```
✅ PRP generated: .context/prp/generated/[filename].md

Summary:
- [1-2 sentence summary]
- Phases: [X phases] (last phase is e2e verification)
- Affected files: [N files]
- Parallelism: [parallel blocks count, or "all sequential"]
- Auto-validation: [✓ passed | ✗ N findings addressed]
```

Then **use AskUserQuestion** to offer next steps:

> "PRP generated. What would you like to do next?"
> Options:
> - "Execute now" — I'll clear context and start `/execute-prp [filename]` with a fresh window
> - "Review first" — I'll stop here so you can review the PRP before executing
> - "Edit PRP" — Let's adjust specific sections before proceeding

If user chooses **"Execute now"**:
1. Tell the user: "Run `/clear` then `/execute-prp [filename]` to start with a clean context."
2. Do NOT attempt to execute the PRP in the same session — the context is already full from PRP generation and will produce worse results.

## Final Checklist (PRP-time, before output)

- [ ] Clarity assessment performed; questions (if any) were targeted, not padded
- [ ] Problem clearly defined
- [ ] "What changes" and "What doesn't change" both filled, mutually exclusive
- [ ] Affected files table is path-level
- [ ] Snippets follow quality rules (compilable, real names, file:line refs)
- [ ] Decisions: impact + new decisions tables filled (or removed if N/A)
- [ ] Validation Gate held; auto-validation subagent dispatched and findings addressed
- [ ] Implementation Plan ordered logically; last phase is e2e verification
- [ ] Parallelism Map filled (or "all phases sequential")
- [ ] Testing strategy included
- [ ] Risks identified with mitigations
- [ ] Reference materials documented (if any were provided)

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely.
