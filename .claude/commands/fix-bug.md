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

Build a complete bug context from all available sources:

1. **Text description** (always present): Use as-is
2. **If --issue N provided:**
```bash
gh issue view N --json title,body,comments
```
3. **If --pr N provided:**
```bash
gh pr view N --json title,body,comments,files,diff
```

Combine all sources into a single `BUG_CONTEXT` block.

### Step 3: Read Project Context

Read these files to understand the project:
- `CLAUDE.md` — project rules, stack, test commands
- `.context/CONTEXT.md` — domain context
- `.context/skills/bug-reproduction/SKILL.md` — bug reproduction patterns (if exists)

From `CLAUDE.md`, identify:
- **Test framework** and **test command** (e.g., `npm test`, `pytest`, `go test`)
- **Lint command** if available
- **Stack** information (language, framework)

If no test framework can be identified, warn the user:
> "No test framework detected in CLAUDE.md. The /fix-bug command requires a test framework to validate fixes. Please update CLAUDE.md with your test commands, or provide the test command now."

Then **use AskUserQuestion** to get the test command, or allow the user to proceed without tests.

### Step 4: Launch Investigator Agent (Phase 1)

Use the **Task tool** with `subagent_type: "general-purpose"`:

```
You are the Investigator agent for a test-driven bug fix.

**Your mission:** Find the root cause of the bug and write a failing test that reproduces it.

**Bug description:**
{BUG_CONTEXT}

**Project stack:**
{stack from CLAUDE.md}

**Test framework:** {test framework}
**Test command:** {test command}

**Bug reproduction skill:**
{paste SKILL.md content if it exists}

**Instructions:**

1. **Search for related code:**
   - Use Grep to search for keywords from the bug description
   - Use Glob to find relevant files
   - Read the files to understand the code path

2. **Identify root cause:**
   - Trace the execution path that triggers the bug
   - Identify the exact file(s), function(s), and line(s) where the bug occurs
   - Explain WHY the bug happens (not just WHERE)

3. **Write a reproduction test:**
   - Use the project's test framework and patterns
   - Test name should describe the bug: "should [expected behavior] when [condition]"
   - Test must assert the CORRECT (expected) behavior
   - The test should FAIL because the bug prevents the correct behavior

4. **Run the test:**
   - Execute the test using the project's test command
   - Confirm the test FAILS
   - Verify it fails for the RIGHT reason (the assertion fails due to the bug, not due to test setup errors)

5. **If test PASSES (bug not reproduced):**
   - Do NOT proceed to fix phase
   - Report what you found and what you tried
   - Include your best understanding of the bug

**Output format:**

## Investigation Results

### Root Cause
[Detailed explanation of what's wrong and why]

### Affected Files
| File | Lines | Issue |
|------|-------|-------|
| [path] | [lines] | [what's wrong] |

### Reproduction Test
- **File:** [path to test file]
- **Test name:** [test function/describe name]
- **Status:** FAILING / PASSING (not reproduced)
- **Failure output:**
```
[test output showing the failure]
```

### Test Code
```
[the full test code written]
```

### Suggested Fix Areas
[Which files/functions need to change and general approach]
```

After the Investigator completes, check the result:

- **If test FAILS (bug reproduced):** Proceed to Step 5
- **If test PASSES (bug not reproduced):** Stop and report to user:
  > "The Investigator could not reproduce the bug with an automated test. Here's what was found: [summary]. Would you like to provide more details or try a different approach?"
  Use **AskUserQuestion** with options: "Provide more details" | "Try different test approach" | "Fix without test" | "Cancel"

### Step 5: Launch Parallel Fix Agents (Phase 2)

Launch N agents (from `--agents` flag, default 3) in a SINGLE message with multiple Task tool calls. All agents run in background (`run_in_background: true`).

Each agent receives the Investigator's output and has a different strategy.

---

#### Fix Agent 1 — Conservative Fix (Background)

Use the **Task tool** with `subagent_type: "general-purpose"` and `run_in_background: true`:

```
You are Fix Agent 1 (Conservative) for a test-driven bug fix.

**Your strategy:** Make the SMALLEST possible change to fix the bug. Prefer the minimal diff. Do not refactor, do not improve surrounding code. Just fix the exact issue.

**Bug context:**
{BUG_CONTEXT}

**Investigator findings:**
{paste Investigator output}

**Test file:** {test file path}
**Test command:** {test command}

**Instructions:**
1. Read the affected files identified by the Investigator
2. Make the minimal change needed to fix the root cause
3. Run the reproduction test: {test command} {test file}
4. Report your results

**Output format:**

## Fix Agent 1: Conservative Fix

### Strategy
Minimal change — smallest diff possible

### Changes Made
| File | Change |
|------|--------|
| [path] | [what was changed and why] |

### Diff
```diff
[the actual diff of changes]
```

### Test Result
- **Reproduction test:** PASS / FAIL
- **Output:**
```
[test output]
```

### Explanation
[Why this fix works]
```

---

#### Fix Agent 2 — Minimal Change Fix (Background)

Use the **Task tool** with `subagent_type: "general-purpose"` and `run_in_background: true`:

```
You are Fix Agent 2 (Minimal Change) for a test-driven bug fix.

**Your strategy:** Focus on the EXACT line(s) causing the issue. One-liner if possible. Think surgically — what's the most precise change?

**Bug context:**
{BUG_CONTEXT}

**Investigator findings:**
{paste Investigator output}

**Test file:** {test file path}
**Test command:** {test command}

**Instructions:**
1. Read the affected files identified by the Investigator
2. Identify the exact line(s) that need to change
3. Make the most precise, surgical fix possible
4. Run the reproduction test: {test command} {test file}
5. Report your results

**Output format:**

## Fix Agent 2: Minimal Change Fix

### Strategy
Surgical change — exact line(s) only

### Changes Made
| File | Change |
|------|--------|
| [path] | [what was changed and why] |

### Diff
```diff
[the actual diff of changes]
```

### Test Result
- **Reproduction test:** PASS / FAIL
- **Output:**
```
[test output]
```

### Explanation
[Why this fix works]
```

---

#### Fix Agent 3 — Refactor Fix (Background)

Use the **Task tool** with `subagent_type: "general-purpose"` and `run_in_background: true`:

```
You are Fix Agent 3 (Refactor) for a test-driven bug fix.

**Your strategy:** Fix the bug AND improve the surrounding code. Better abstractions, clearer logic, defensive coding. Make the code less likely to have similar bugs in the future.

**Bug context:**
{BUG_CONTEXT}

**Investigator findings:**
{paste Investigator output}

**Test file:** {test file path}
**Test command:** {test command}

**Instructions:**
1. Read the affected files identified by the Investigator
2. Fix the root cause
3. Improve the surrounding code: better variable names, clearer logic, edge case handling, comments if needed
4. Run the reproduction test: {test command} {test file}
5. Report your results

**Output format:**

## Fix Agent 3: Refactor Fix

### Strategy
Fix + improve — better code quality around the bug

### Changes Made
| File | Change |
|------|--------|
| [path] | [what was changed and why] |

### Diff
```diff
[the actual diff of changes]
```

### Test Result
- **Reproduction test:** PASS / FAIL
- **Output:**
```
[test output]
```

### Explanation
[Why this fix works and what was improved]
```

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

```
You are the Reviewer agent for a test-driven bug fix.

**Your mission:** Evaluate all fix attempts and select (or combine) the best solution.

**Bug context:**
{BUG_CONTEXT}

**Investigator findings:**
{paste Investigator output}

**Fix Agent Results:**

{paste ALL fix agent outputs}

**Test command:** {test command}

**Instructions:**

1. **Count successful fixes** (reproduction test passed)

2. **If 0 agents succeeded:**
   - Report failure
   - Summarize what each agent tried
   - Identify the most promising partial approach
   - Output recommendation: "No fix found"

3. **If 1 agent succeeded:**
   - Verify the fix by re-running the reproduction test
   - Run the full test suite to check for regressions
   - Output the fix details

4. **If >1 agents succeeded:**
   - Compare each successful fix:
     - Diff size (smaller is better)
     - Code quality (clarity, maintainability)
     - Test coverage (does the fix handle edge cases?)
     - Risk of regression (how much was changed?)
   - Attempt to combine the best aspects into an optimized fix
   - If combined fix passes reproduction test: include it as an option
   - If combined fix fails: discard it

5. **Run full test suite** on the recommended fix to check for regressions

6. **Generate the fix comparison**

**Output format:**

## Review Results

### Summary
- Agents that succeeded: [N of N]
- Recommended fix: [Agent N: strategy name] or [Combined]

### Fix Comparison (if >1 succeeded)
| Agent | Strategy | Diff Size | Test Pass | Quality Notes |
|-------|----------|-----------|-----------|---------------|

### Recommended Fix
- **Source:** [Agent N / Combined]
- **Files changed:** [N]
- **Diff size:** [N lines]
- **Why this fix:** [reasoning]

### Changes to Apply
| File | Change |
|------|--------|

```diff
[the full diff to apply]
```

### Regression Check
- Reproduction test: PASS / FAIL
- Full test suite: PASS / FAIL / [specific failures]

### Alternative Fixes (if applicable)
[Brief description of other successful fixes not selected]
```

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

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
