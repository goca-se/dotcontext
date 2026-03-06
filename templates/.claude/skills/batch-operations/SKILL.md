# Skill: Batch Operations

## When to Use

- Refactoring that touches more than 5 files
- Library or API migrations across the codebase
- Renaming symbols, imports, or paths project-wide
- Adding boilerplate or patterns to many files
- Any change where "do it all at once" risks context overflow or silent failures

## Workflow

### Step 1: Scope — Plan Before Touching Anything

Identify every file affected. Map old → new without making changes.

1. Search for all files that match the change (imports, usages, references)
2. List them grouped by directory
3. Note edge cases (re-exports, dynamic imports, config files, tests)
4. Present the plan to the user before proceeding

**Do not skip this step.** If the scope is unclear, use the Agent tool with `subagent_type=Explore` to map the codebase first.

### Step 2: Batch — Execute in Directory Groups

Process changes in small batches, grouped by directory or module.

1. Pick a batch (one directory or a logical group of ~5-10 files)
2. Make the changes in that batch
3. Run targeted tests for the affected files
4. Confirm tests pass before moving to the next batch

**If a batch fails:** Stop. Fix the issue in that batch before continuing. Do not proceed with broken state.

### Step 3: Verify — Confirm the Full Change

After all batches are complete:

1. Run `git diff --stat` to review the scope of changes
2. Run the full test suite
3. Run type checking / linting if available
4. Present the results to the user

### Step 4: Clean Up

- Remove any dead code left behind by the migration
- Check for unused imports
- Verify no files were missed (`grep` for the old pattern)

## Parallel Processing with Subagents

For large migrations (20+ files), delegate each directory batch to a subagent:

- Each subagent gets one directory to process
- Subagents run tests for their batch independently
- Results are collected and verified together

This prevents context window saturation and speeds up execution.

## Constraints

- **Never modify files outside the stated scope** without asking
- **Never skip the planning step** — list affected files first
- **Always test between batches** — do not batch all changes then test once at the end
- **Preserve git history** — use `git mv` for file renames so history follows

## Anti-Patterns to Avoid

- Making all changes in one pass without testing between batches
- Reading every file in the project before starting
- Fixing unrelated issues discovered during the migration
- Skipping the verification step because "it should work"
