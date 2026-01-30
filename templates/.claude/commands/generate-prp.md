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

Ask the user to clarify if needed:
- What problem is being solved?
- Who are the affected users?
- Any constraints or non-negotiables?

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
