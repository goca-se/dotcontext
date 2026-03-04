# Skill: Bug Reproduction

## When to Use

- You encounter a bug that needs fixing
- You're working on a bug report or issue
- Before attempting ANY fix — always reproduce first
- When using the `/fix-bug` command

## Test Framework

- **Framework:** Manual testing + shellcheck (bash CLI project, no unit test framework)
- **Run command:** `bash -n dotcontext` (syntax check), `shellcheck dotcontext` (lint)
- **Test directory:** N/A — testing is manual via `dotcontext init` in a temp directory

## How to Reproduce a Bug

### Step 1: Understand the Bug

Read the bug description carefully. Identify:
- **Expected behavior:** What should happen?
- **Actual behavior:** What happens instead?
- **Trigger conditions:** When does it occur? (specific input, state, timing)

Check for additional context:
- Error logs or stack traces
- Screenshots or recordings
- Related GitHub issues or PRs

### Step 2: Locate the Code

Search for the affected code path:

```bash
# Search by error message
grep -r "error message text" src/

# Search by function/method name
grep -r "functionName" src/

# Search by route/endpoint
grep -r "/api/endpoint" src/
```

Read the code and trace the execution path from trigger to failure.

### Step 3: Write a Failing Test

Write a test that:
1. Sets up the conditions that trigger the bug
2. Performs the action that causes the failure
3. Asserts the EXPECTED (correct) behavior

The test must **FAIL** — proving the bug exists.

```
# Example pattern (adapt to your framework):
describe("bug: [short description]") {
  it("should [expected behavior] when [condition]") {
    // Arrange: set up the conditions
    // Act: perform the action that triggers the bug
    // Assert: check for correct behavior (this should FAIL)
  }
}
```

### Step 4: Verify the Failure

Run the test and confirm it fails:

```bash
# Run the specific test
[test command] [test file]
```

Check that the test fails for the RIGHT reason:
- The assertion should fail because of the bug, not because of a typo in the test
- The error message should relate to the actual bug behavior
- If the test passes, the bug is not reproduced — revisit Step 1

### Step 5: Fix and Verify

After implementing the fix:
1. Run the reproduction test — it should now PASS
2. Run the full test suite — no regressions

```bash
# Run reproduction test
[test command] [test file]

# Run full suite
[test command]
```

## Anti-Patterns

- Don't mock the bug away — test the real code path
- Don't write a test that passes — it must FAIL first
- Don't fix the bug before writing the test
- Don't write overly broad tests — isolate the specific bug
- Don't skip running the test before fixing — you need to SEE it fail
- Don't assume the first failure is the right failure — verify the error relates to the bug

## UI Bugs

### Markdown Test Plans

When the bug involves UI behavior that can't easily be unit tested, create a test plan document:

```markdown
## Test Plan: [Bug Description]

### Steps to Reproduce
1. Navigate to [URL/page]
2. [Action 1]
3. [Action 2]
4. Expected: [what should happen]
5. Actual: [what happens instead]

### Validation Method
- [ ] Screenshot comparison
- [ ] DOM element assertion
- [ ] Network request validation
- [ ] Console error check
```

### Browser Validation

- Prefer screenshots over selector-based assertions (less fragile)
- Run browser checks in subagents for isolation
- Document visual references with file paths

### E2E Test Patterns

- **E2E Framework:** N/A (CLI tool — test via manual invocation)
- **Run command:** `dotcontext init --yes --no-setup` in a temp directory
- **Test directory:** N/A

## Examples from This Codebase

This project is a bash CLI with markdown command templates. Bug reproduction involves:
- **CLI bugs:** Run `dotcontext init` or `dotcontext update --templates` in a temp directory and check output
- **Command template bugs:** Invoke the slash command in Claude Code and verify behavior
- **Template bugs:** Check that files are downloaded correctly and contain expected content
- **Syntax validation:** `bash -n dotcontext` catches syntax errors
