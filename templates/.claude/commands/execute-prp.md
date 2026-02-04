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

## Decision Compliance Check

**CRITICAL:** Before and during implementation, check if any changes conflict with existing ADRs in `.context/decisions/`.

### Before each phase:
1. Read all ADRs in `.context/decisions/`
2. Identify if any planned changes would violate or modify an existing decision

### If a conflict is detected:

**Use AskUserQuestion tool** with these options:

```
"This implementation would conflict with ADR-XXX: [title].

The decision states: [brief summary]
The conflict: [what would change]

How would you like to proceed?"

Options:
1. "Update the decision" - Proceed and I'll update the ADR with a new version
2. "Find alternative approach" - Suggest ways to implement without changing the decision
3. "Keep current decision" - Skip this part of the implementation
4. "Let Claude decide" - Choose the best approach based on context
```

### If updating a decision:

1. **Increment the version** in the ADR file:
```markdown
**Version:** 1.0 → **Version:** 2.0
```

2. **Add to History section:**
```markdown
## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial decision |
| 2.0 | 2026-02-02 | Updated due to [PRP name]: [what changed] |
```

3. **If decision is completely replaced**, create new ADR and mark old as Superseded:
```markdown
**Status:** Superseded by ADR-XXX
```

### If finding alternative approach:

Suggest concrete alternatives that:
- Achieve the PRP goals
- Don't violate existing decisions
- May require adjusting the PRP scope

## Before Starting

**Check Reference Materials section** in the PRP:
- If files are listed, **read/view each file** before proceeding
- If visual references exist (images, PDFs, layouts), consult them to understand the expected result
- If referenced files are missing or inaccessible, ask the user to provide them

**Use AskUserQuestion tool** to confirm:
- Which PRP to execute (if $ARGUMENTS is ambiguous)
- Any phases to skip or focus on
- Any constraints or preferences for implementation

### Worktree Isolation (Recommended)

**Always ask with AskUserQuestion tool** if the user wants to create an isolated worktree for this work:

> "Do you want to create an isolated worktree for this [feature/bugfix/hotfix/chore]?
> This allows you to work on other tasks without stashing or losing context."

**Determine the type** by analyzing the PRP content:
- `feature/` - New functionality
- `bugfix/` - Bug corrections
- `hotfix/` - Urgent production fixes
- `chore/` - Maintenance, refactoring, docs
- `experiment/` - Spikes, POCs, explorations

**If user accepts**, create the worktree:

```bash
# Get project name from current directory
PROJECT_NAME=$(basename $(pwd))

# Create worktree with appropriate branch
git worktree add ../${PROJECT_NAME}-<prp-slug> -b <type>/<prp-slug>

# Example: ../myproject-user-auth -b feature/user-auth
```

**Then inform the user:**
```
✅ Worktree created at: ../<project>-<prp-slug>
   Branch: <type>/<prp-slug>

To switch to this worktree:
  cd ../<project>-<prp-slug>

To return to main workspace:
  cd ../<project>

When finished, clean up with:
  git worktree remove ../<project>-<prp-slug>
```

**If user declines**, proceed normally in the current workspace.

## Progress Tracking

**IMPORTANT:** Update the PRP file as you progress:

### After completing each task:
Mark the checkbox in the PRP file:
```markdown
# Before
1. [ ] Implement user model

# After
1. [x] Implement user model
```

### After completing each phase:
1. Mark all tasks as `[x]` in that phase
2. Add completion note below the phase:
```markdown
**Validation:** [How to verify this phase is complete]

✅ **Completed:** YYYY-MM-DD - [brief summary of what was done]
```

### After meeting each success criterion:
Mark it in the Success Criteria section:
```markdown
# Before
- [ ] Users can log in with email/password

# After
- [x] Users can log in with email/password
```

### Update the Status:
Change `**Status:** Draft` to `**Status:** In Progress` when starting, and `**Status:** Completed` when done.

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

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
