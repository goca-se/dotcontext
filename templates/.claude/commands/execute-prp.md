# Execute PRP

Execute the PRP specified in $ARGUMENTS.

## Process

1. **Read the PRP** completely from `.context/prp/generated/`
2. **Check prerequisites** (pending migrations, dependencies, etc)
3. **Implement in the order defined** in the PRP
4. **Validate each step:**
   - Code compiles
   - Linting passes
   - Tests pass
5. **Fix issues** before proceeding to next step

## During Implementation

- Follow patterns in `.context/skills/`
- Respect decisions in `.context/decisions/`
- Check `CLAUDE.md` for critical rules

## Before Starting

Ask the user to confirm:
- Which PRP to execute (if $ARGUMENTS is ambiguous)
- Any phases to skip or focus on

## On Each Phase Completion

```
✅ Phase X complete
- [what was done]
- [tests status]
```

## When Finished

Run the project's test/lint commands as defined in `CLAUDE.md`.

## If Something Fails

1. Stop immediately
2. Analyze the error
3. Fix before continuing
4. Never accumulate errors
5. Inform the user what went wrong and what was fixed
