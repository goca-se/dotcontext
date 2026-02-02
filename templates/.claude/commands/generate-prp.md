# Generate PRP

Generate a PRP (Product Requirements Prompt) for the feature described in $ARGUMENTS.

## Process

1. **Read the request** in $ARGUMENTS
2. **Analyze the codebase** to understand existing patterns
3. **Consult relevant skills** in `.context/skills/`
4. **Check decisions** in `.context/decisions/`
5. **Generate PRP** following the template in `.context/prp/templates/feature.md`

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

## After Generating

Show the user:
```
✅ PRP generated: .context/prp/generated/[filename].md

Summary:
- [1-2 sentence summary]
- Phases: [X phases]
- Estimated scope: [files/modules affected]

Ready to execute? Run: /execute-prp [filename]
```
