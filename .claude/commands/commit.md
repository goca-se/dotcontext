# Commit

Smart commit workflow with style-aware message generation and interactive staging.

**Usage:** `/commit [--amend]`
- Default: create a new commit with AI-generated message
- `--amend`: amend the previous commit instead of creating a new one

## Process

### Step 1: Detect Commit Style

Read the last 10 commit messages to detect the project's style:

```bash
git log --oneline -10 --format="%s"
```

Classify the style:
- **Conventional Commits** — if majority match `type(scope): description` or `type: description` (e.g., `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`, `perf:`, `build:`, `style:`)
- **Freeform** — if no dominant pattern is detected

Remember the detected style for message generation in Step 5.

### Step 2: Check Working Tree Status

```bash
git status --short
```

Categorize files:
- **Staged** (lines starting with `M `, `A `, `D `, `R ` — first column)
- **Unstaged modifications** (lines starting with ` M`, ` D` — second column)
- **Untracked** (lines starting with `??`)

If the working tree is completely clean (no staged, unstaged, or untracked):
> "Nothing to commit. Working tree is clean."
Stop here.

### Step 3: Smart Staging

**If files are already staged:** Skip to Step 4. Show what's staged:
> "Found [N] staged files. Proceeding with those."

**If no files are staged but there are unstaged/untracked changes:**

Group files by directory and type, then **use AskUserQuestion** (multiSelect: true):
> "No files are staged. Which changes do you want to commit?"

Build options dynamically from the file list. Group logically:
- If all changes are in the same directory: list individual files
- If changes span multiple directories: offer directory-level grouping + "All changes"
- Always include "All changes" as the first option
- Limit to 4 options max (use grouping to fit)

After selection, stage the chosen files:
```bash
git add [selected files]
```

### Step 4: Analyze the Diff

Get the staged diff for analysis:

```bash
git diff --staged
```

Also get the file list:
```bash
git diff --staged --name-only
```

Understand:
- What was added, removed, or modified
- Which components/modules are affected
- The nature of the change (new feature, bug fix, refactor, docs, test, chore, etc.)

### Step 5: Generate Commit Message

Based on the detected style (Step 1) and diff analysis (Step 4):

**If Conventional Commits style:**
```
type(scope): concise description

[Optional body — only if the change needs explanation beyond the subject line]
```

Type selection rules:
- `feat` — new feature or capability
- `fix` — bug fix
- `refactor` — code restructuring, no behavior change
- `docs` — documentation only
- `chore` — maintenance, dependencies, build
- `test` — adding or updating tests
- `style` — formatting, no logic change
- `perf` — performance improvement
- `ci` — CI/CD changes
- `build` — build system or dependency changes

Scope: the primary module/component affected (optional, use if project uses scopes)

**If Freeform style:**
Match the project's capitalization, tense, and length patterns from Step 1.

**Message rules:**
- Subject line: max 72 characters
- Use imperative mood ("Add feature" not "Added feature")
- Focus on WHY, not just WHAT
- Body only if the subject line isn't self-explanatory
- No trailing period on subject line

### Step 6: Confirm with User

**Use AskUserQuestion:**
> "Commit message:"
>
> `[generated message]`

Options:
- "Commit" (Recommended) — Use this message as-is
- "Edit message" — Let me modify the message
- "Cancel" — Abort the commit

**If user selects "Edit message":**
**Use AskUserQuestion** with a text input:
> "Enter your commit message (or modify the suggested one):"
Show the generated message as the default/suggestion.

### Step 7: Execute Commit

```bash
git commit -m "[final message]"
```

If `--amend` flag was provided:
```bash
git commit --amend -m "[final message]"
```

### Step 8: Show Result

Display the commit result:

```bash
git log --oneline -1
```

```
Committed: [short hash] [message]
Files: [N] changed, [+additions] / [-deletions]
Branch: [current branch]
```

## Guidelines

- Never auto-commit without user confirmation (Step 6)
- Never stage files without user selection (Step 3)
- Respect the project's existing commit style
- Keep messages concise and meaningful
- If the diff is very large (>500 lines), summarize the key changes rather than listing everything

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
