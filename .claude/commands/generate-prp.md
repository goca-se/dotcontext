# Generate PRP

Generate a PRP (Product Requirements Prompt) for the feature described in $ARGUMENTS.

## Process

1. **Read the request** in $ARGUMENTS
2. **Analyze the codebase** to understand existing patterns
3. **Consult relevant skills** in `.claude/skills/`
4. **Check decisions** in `.context/decisions/` - identify any that might be affected
5. **Generate PRP** following the template in `.context/prp/templates/feature.md`

## Decision Awareness

**Before generating the PRP**, read all ADRs in `.context/decisions/` and identify:

1. **Decisions that support the feature** - Reference them in Technical Design
2. **Decisions that might conflict** - Flag them in Risks section
3. **Decisions that need updating** - Add to Implementation Plan as explicit task
4. **New decisions required** - Architectural choices this feature will introduce

### Existing Decisions Impact

If the feature would require changing an existing decision, include in the PRP:

```markdown
## Decision Impact

| ADR | Current Decision | Proposed Change | Action |
|-----|------------------|-----------------|--------|
| ADR-XXX | [current] | [what would change] | Update/Supersede |
```

### New Decisions Required

If the feature requires significant architectural choices, identify them upfront:

```markdown
## New Decisions

This feature will require the following architectural decisions:

| Decision | Context | Options to Consider |
|----------|---------|---------------------|
| [e.g., Auth strategy] | [Why needed] | [JWT, Sessions, OAuth] |
| [e.g., Storage approach] | [Why needed] | [SQL, NoSQL, File] |

**Action:** Create ADRs for these decisions in Phase 1 before implementation.
```

Add creating these ADRs as explicit tasks in Phase 1 of the Implementation Plan:
```markdown
### Phase 1: Setup & Decisions

1. [ ] Create ADR-XXX: [Decision title]
2. [ ] Create ADR-YYY: [Decision title]
3. [ ] [Other setup tasks...]
```

This ensures architectural decisions are documented before code is written.

## Output

Save the generated PRP in `.context/prp/generated/YYYYMMDD-[feature-slug].md`

Use today's date and a URL-friendly slug of the feature name.

## Before Generating

**MANDATORY: Create and ask 10 clarifying questions using AskUserQuestion tool.**

Before writing any PRP, generate 10 unique questions specific to the feature being requested. These questions must be created fresh for each PRP - do not use a fixed list.

Your questions should explore:
- The problem and its context
- Long-term implications and scalability
- Performance considerations
- How this feature will interact with other parts of the system
- What the end result should look like
- Any other aspects that need clarification

Think deeply about what information you need to write a comprehensive PRP. The questions should be tailored to the specific feature, the project's domain, and the existing codebase patterns.

Use AskUserQuestion tool with batches of 3-4 questions at a time until all 10 are answered.

**Do NOT skip this step. Do NOT proceed without answers.**

## Reference Material Handling

If the user provides or mentions visual references (images, PDFs, designs, layouts):

1. **Read/view the file** using the Read tool to understand the content
2. **Extract key details** in text form (layout structure, colors, spacing, components, behavior)
3. **Document the file path** in the Reference Materials section of the PRP
4. **Add explicit task** in Phase 1: "Review reference materials in Reference Materials section"

**Important:** Visual information cannot be fully captured in text. Always preserve file paths so the executor can consult the original materials.

## Checklist

Before finishing, confirm:
- [ ] Problem clearly defined
- [ ] Scope is realistic (not too broad)
- [ ] Affected modules/packages identified
- [ ] Dependencies and integrations documented
- [ ] Implementation phases are ordered logically
- [ ] Each phase has clear validation criteria
- [ ] Testing strategy included
- [ ] Risks identified with mitigations
- [ ] Reference materials documented (if any were provided)

## After Generating

Show the user:
```
✅ PRP generated: .context/prp/generated/[filename].md

Summary:
- [1-2 sentence summary]
- Phases: [X phases]
- Estimated scope: [files/modules affected]
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

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
