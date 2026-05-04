# Fix Bug — Test-Driven Bug Fixing with Parallel Subagents

Investigate a bug, write a failing test that proves it exists, launch parallel agents to fix it, then select the best solution. Zero questions — goes straight from description to investigation.

**Usage:** `/fix-bug [description]`
- `/fix-bug "checkout button doesn't save address"` — Fix from text description
- `/fix-bug "login fails" --issue 42` — Include GitHub issue context
- `/fix-bug "regression in checkout" --pr 123` — Include PR context
- `/fix-bug "timeout on upload" --agents 5` — Use 5 parallel fix agents

## Process

### Step 1: Parse Input

Extract from `$ARGUMENTS`:
- **description**: The bug description (required — everything before flags)
- **--issue N**: GitHub issue number (optional)
- **--pr N**: GitHub PR number (optional)
- **--agents N**: Number of parallel fix agents, default 3 (optional)

If no description is provided and no --issue/--pr flag, stop and tell the user:
> "Please provide a bug description. Example: `/fix-bug "login fails with empty password"`"

### Step 2: Gather Bug Context

Read `.claude/skills/git-platform/SKILL.md` to detect the platform and use the correct CLI.

Build a complete bug context from all available sources:

1. **Text description** (always present): Use as-is
2. **If --issue N provided:** Use the detected platform CLI to fetch the issue (e.g., `gh issue view N`, `glab issue view N`, `az boards work-item show --id N`)
3. **If --pr N provided:** Use the detected platform CLI to fetch the PR/MR (e.g., `gh pr view N`, `glab mr view N`, `az repos pr show --id N`)
4. **If error logs / stack traces are included:** Extract every source file path mentioned in the trace — these are the starting points for investigation, not the bug description text.

Combine all sources into a single `BUG_CONTEXT` block. Focus on **root causes, not symptoms** — if the user says "fix the null check", rephrase as "find why the value is null" in the context.

### Step 3: Read Project Context

Read these files to understand the project:
- `CLAUDE.md` — project rules, stack, test commands
- `.context/CONTEXT.md` — domain context
- `.claude/skills/bug-reproduction/SKILL.md` — bug reproduction patterns (if exists)
- `.context/bugs/` — check for previous similar bugs (patterns may repeat)

From `CLAUDE.md`, identify:
- **Test framework** and **test command** (e.g., `npm test`, `pytest`, `go test`)
- **Lint command** if available
- **Stack** information (language, framework)

If no test framework can be identified, warn the user:
> "No test framework detected in CLAUDE.md. The /fix-bug command requires a test framework to validate fixes. Please update CLAUDE.md with your test commands, or provide the test command now."

Then **use AskUserQuestion** to get the test command, or allow the user to proceed without tests.

### Step 4: Launch Investigator Agent (Phase 1)

Use the **Task tool** with `subagent_type: "general-purpose"`:

Read `.claude/agents/fix-bug/investigator.md` for the agent prompt. Substitute `{bug_context}`, `{stack}`, `{test_framework}`, `{test_command}`, and `{reproduction_skill}` with actual values.

After the Investigator completes, check the result:

- **If test FAILS (bug reproduced):** Proceed to Step 5
- **If test PASSES (bug not reproduced):** Stop and report to user:
  > "The Investigator could not reproduce the bug with an automated test. Here's what was found: [summary]. Would you like to provide more details or try a different approach?"
  Use **AskUserQuestion** with options: "Provide more details" | "Try different test approach" | "Fix without test" | "Cancel"

### Step 5: Launch Parallel Fix Agents (Phase 2)

Launch N agents (from `--agents` flag, default 3) in a SINGLE message with multiple Task tool calls. All agents run in background (`run_in_background: true`).

Each agent receives the Investigator's output and has a different strategy. Read the agent prompt files and substitute `{bug_context}`, `{investigator_output}`, `{test_file}`, and `{test_command}` with actual values.

---

#### Fix Agent 1 — Conservative Fix (Background)

Use the **Task tool** with `subagent_type: "general-purpose"` and `run_in_background: true`:

Read `.claude/agents/fix-bug/fix-conservative.md` for the agent prompt.

---

#### Fix Agent 2 — Minimal Change Fix (Background)

Use the **Task tool** with `subagent_type: "general-purpose"` and `run_in_background: true`:

Read `.claude/agents/fix-bug/fix-minimal.md` for the agent prompt.

---

#### Fix Agent 3 — Refactor Fix (Background)

Use the **Task tool** with `subagent_type: "general-purpose"` and `run_in_background: true`:

Read `.claude/agents/fix-bug/fix-refactor.md` for the agent prompt.

---

#### Additional Fix Agents (if --agents > 3)

For agents 4+, use hybrid strategies. Alternate between:
- **Agent 4:** "Fix with additional test coverage" — fix the bug and write extra edge case tests
- **Agent 5:** "Alternative root cause" — consider if the Investigator's root cause is correct, explore alternative causes
- **Agent 6+:** "Creative fix" — try an unconventional approach

Each follows the same output format with their strategy clearly labeled.

### Step 6: Collect All Fix Results

Wait for ALL fix agents to complete. Read each background agent's output.

**IMPORTANT:** Wait for ALL agents. Do not proceed until every agent has finished, even if some finish early.

### Step 7: Launch Reviewer Agent (Phase 3)

Use the **Task tool** with `subagent_type: "general-purpose"`:

Read `.claude/agents/fix-bug/reviewer.md` for the agent prompt. Substitute `{bug_context}`, `{investigator_output}`, `{fix_results}` (all fix agent outputs concatenated), and `{test_command}` with actual values.

### Step 8: Present Fix to User

Based on the Reviewer's output:

**If 0 fixes succeeded:**
Report failure and **use AskUserQuestion**:
> "None of the [N] fix agents found a working solution. Here's what was tried: [summary]"
> Options: "Retry with more agents" | "Provide hints for fix direction" | "Fix manually" | "Cancel"

**If 1 fix succeeded:**
Apply the fix and inform the user. No question needed.

**If >1 fixes succeeded:**
**Use AskUserQuestion** to let the user choose:
> "Multiple fix strategies worked. Which would you like to apply?"
> Options showing each successful fix with brief description (e.g., "Conservative — 3 lines changed" | "Refactor — 12 lines, improved error handling" | "Combined — best of both")

### Step 9: Apply Fix and Generate Bug Report

1. **Apply the chosen fix** (the files should already be modified by the winning agent)
2. **Run the reproduction test** one final time to confirm
3. **Run the full test suite** to verify no regressions
4. **Generate the bug report** and save to `.context/bugs/`:

Generate filename: `YYYYMMDD-{slugified-description}.md`
If file exists, append `-2`, `-3`, etc.

```markdown
# Bug Fix: [Short Description]
> Fixed: YYYY-MM-DD | Duration: ~Xmin | Agents: N

## Bug Description
[Original description from user/issue/PR]

## Root Cause
[What was actually wrong and why — from Investigator]

### Affected Files
| File | Lines | Issue |
|------|-------|-------|
| [path] | [lines] | [what was wrong] |

## Reproduction Test
- **File:** [test file path]
- **Test name:** [test function/describe name]

```
[test code]
```

## Fix Applied
- **Strategy:** [Conservative/Minimal/Refactor/Combined]
- **Files changed:** [N]
- **Diff size:** [N lines]

### Changes
| File | Change |
|------|--------|
| [path] | [what was changed and why] |

```diff
[actual diff]
```

## Alternative Fixes Considered
[If multiple agents succeeded, document the alternatives not chosen]

## Regression Check
- Reproduction test: PASS
- Full test suite: PASS / [issues]

## Metadata
- Input: [original text / issue #N / PR #N]
- Agents used: [N]
- Successful fixes: [N of N]
- Strategy selected: [which and why]
```

### Step 10: Final Report

Display a summary:

```
Bug fixed!

Bug: [short description]
Root cause: [1-line summary]
Strategy: [Conservative/Minimal/Refactor/Combined]
Files changed: [N]

Tests:
  Reproduction test: PASS
  Full test suite: PASS

Report saved to: .context/bugs/[filename]
```

## Guidelines

### Agent Communication
- Follows ADR-009: Multi-Agent Orchestration Pattern
- No temp files — all data flows through Task tool returns
- Investigator output passed as context to fix agents
- All fix agent outputs passed as context to Reviewer
- Fix agents run in background (`run_in_background: true`)

### Test-First Principle (ADR-011)
- NEVER attempt a fix before writing a reproduction test
- ALWAYS verify the test fails before proceeding
- If test passes (bug not reproduced), stop and report

### Zero Questions Policy (ADR-011 Exception to ADR-005)
- Do NOT ask clarifying questions at the start
- Go straight from input to investigation
- AskUserQuestion used ONLY for:
  - No test framework detected
  - Test doesn't reproduce the bug
  - Fix selection (>1 succeeded)
  - All fixes failed

### All Agents Run to Completion
- Even if one agent finds a fix quickly, let all others finish
- This ensures the best possible fix, not just the first one
- Use `run_in_background: true` for all fix agents

## Debugging Strategies

When the bug is hard to find, use these techniques in order:

1. **Stack trace analysis** — Read every source file in the trace. The bug is often NOT in the file the error points to — trace upstream.
2. **Binary search** — Find the midpoint of the execution path, check if data is correct there, narrow to the broken half. Repeat.
3. **Type tracing** — For type errors, trace the value through every transformation from origin to failure. Log the type/shape at each step.
4. **Git bisect** — If the bug is a regression, use `git bisect` to find the introducing commit before diving into code.
5. **Constraint isolation** — Remove components until the bug disappears. The last removed component is the cause.

For **intermittent / async bugs**, look for:
- Shared mutable state between concurrent operations
- Missing `await` or unhandled promise rejections
- Assumptions about execution order
- Premature resource cleanup

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you tried, what you expected, and what happened instead
3. **Use AskUserQuestion tool** with concrete options:
   - "Try a different debugging approach (binary search / git bisect / constraint isolation)"
   - "Provide more context about the bug"
   - "Fix without reproduction test"
   - "Cancel"

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
