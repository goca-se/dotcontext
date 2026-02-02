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
