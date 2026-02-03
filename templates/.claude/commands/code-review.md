# Code Review

Review the code changes using multiple specialized agents with confidence-based scoring to filter false positives.

**Usage:** `/code-review [--comment]`
- Default: outputs review to terminal
- `--comment`: posts review as PR comment on GitHub

## Execution Flow

### Step 1: Pre-flight Checks

Run these checks first. If any fail, skip the review and explain why:

```bash
# Check if we're in a git repo with GitHub remote
gh repo view --json name 2>/dev/null

# Check PR status (skip if closed, draft, or already reviewed by this tool)
gh pr view --json state,isDraft,comments
```

Skip review if:
- PR is closed or merged
- PR is draft
- PR already has a "## Code Review" comment from this tool
- Changes are trivial (only whitespace, comments, or auto-generated files)

### Step 2: Gather Context

Collect all relevant context before launching agents:

1. **Get the PR diff:**
```bash
gh pr diff
```

2. **Find all CLAUDE.md files** (project guidelines):
```bash
find . -name "CLAUDE.md" -o -name "*.claude.md" | head -20
```

3. **Read CLAUDE.md files** found above to understand project rules

4. **Get PR metadata:**
```bash
gh pr view --json title,body,files,additions,deletions
```

### Step 3: Launch Parallel Review Agents

Use the **Task tool** to launch 4 agents in parallel. Each agent receives:
- The full PR diff
- All CLAUDE.md content found
- Their specific mission

**IMPORTANT:** Launch all 4 agents in a SINGLE message with multiple Task tool calls.

---

#### Agent 1: CLAUDE.md Compliance (Primary)

```
You are a code review agent focused on CLAUDE.md compliance.

**Your mission:** Check if the PR changes violate any rules defined in CLAUDE.md files.

**CLAUDE.md content:**
{paste all CLAUDE.md content here}

**PR diff:**
{paste diff here}

**Instructions:**
1. For each rule in CLAUDE.md, check if any change violates it
2. Only report violations that are EXPLICITLY mentioned in CLAUDE.md
3. Do NOT report general best practices unless CLAUDE.md mentions them
4. For each issue, cite the specific CLAUDE.md rule being violated

**Output format (JSON array):**
[
  {
    "file": "path/to/file.ts",
    "line_start": 42,
    "line_end": 45,
    "issue": "Description of the violation",
    "rule": "The exact CLAUDE.md rule being violated",
    "severity": "critical|major|minor"
  }
]

If no violations found, return: []
```

---

#### Agent 2: CLAUDE.md Compliance (Secondary)

Same prompt as Agent 1. Redundancy ensures we catch compliance issues.

---

#### Agent 3: Bug Detection

```
You are a code review agent focused on finding bugs.

**Your mission:** Find obvious bugs, logic errors, and correctness issues in the PR changes.

**PR diff:**
{paste diff here}

**Focus areas:**
- Logic errors and incorrect conditions
- Null/undefined access without checks
- Off-by-one errors
- Race conditions
- Resource leaks (unclosed connections, missing cleanup)
- Error handling gaps
- Edge cases not handled
- Type mismatches

**DO NOT report:**
- Style issues (linters catch these)
- Pre-existing issues not introduced in this PR
- Hypothetical issues in code paths not touched
- General "could be improved" suggestions

**Output format (JSON array):**
[
  {
    "file": "path/to/file.ts",
    "line_start": 42,
    "line_end": 45,
    "issue": "Description of the bug",
    "evidence": "Why this is definitely a bug",
    "severity": "critical|major|minor"
  }
]

If no bugs found, return: []
```

---

#### Agent 4: Security & History Analysis

```
You are a code review agent focused on security and historical context.

**Your mission:**
1. Find security vulnerabilities in the PR changes
2. Use git blame/history to understand if changes break existing patterns

**PR diff:**
{paste diff here}

**Security checklist:**
- Hardcoded secrets or credentials
- SQL injection vulnerabilities
- XSS vulnerabilities
- Command injection
- Path traversal
- Insecure deserialization
- Missing authentication/authorization
- Sensitive data exposure
- CSRF vulnerabilities

**History analysis:**
Run `git blame` on modified files to understand:
- Are the changes consistent with how the file was previously written?
- Is there a pattern being broken?

**Output format (JSON array):**
[
  {
    "file": "path/to/file.ts",
    "line_start": 42,
    "line_end": 45,
    "issue": "Description of the security issue or pattern break",
    "category": "security|pattern-violation",
    "severity": "critical|major|minor"
  }
]

If no issues found, return: []
```

### Step 4: Score Each Issue

After all agents complete, collect their findings and score each issue for confidence (0-100):

**Scoring criteria:**
- **90-100**: Definite issue with clear evidence (e.g., hardcoded password, null access on required field)
- **70-89**: Likely issue but some uncertainty (e.g., possible race condition, edge case)
- **50-69**: Possible issue, needs human judgment (e.g., unclear if intentional)
- **0-49**: Probably false positive (e.g., looks wrong but might be intentional)

**Scoring questions to ask yourself:**
1. Is there concrete evidence this is a real issue?
2. Could this be intentional or handled elsewhere?
3. Does the CLAUDE.md explicitly mention this rule?
4. Is this introduced by the PR or pre-existing?

### Step 5: Filter and Deduplicate

1. **Remove duplicates** - If multiple agents found the same issue, keep only one
2. **Filter by confidence** - Remove all issues with score < 80
3. **Sort by severity** - critical → major → minor

### Step 6: Generate Output

**If `--comment` flag is present:**
Post the review as a PR comment using:
```bash
gh pr comment --body "$(cat <<'EOF'
## Code Review

{review content}
EOF
)"
```

**Output format:**

```markdown
## Code Review

**Summary:** [1-2 sentence overview]

### Critical Issues
[Issues that must be fixed before merging]

1. **[Issue title]** (confidence: 95)

   [file.ts:42-45](https://github.com/{owner}/{repo}/blob/{sha}/file.ts#L42-L45)

   [Description of the issue and why it matters]

   **Suggestion:** [How to fix it]

### Major Issues
[Important issues that should be addressed]

### Minor Issues
[Small improvements, optional]

### What's Good ✓
[Positive aspects worth acknowledging - good patterns, clean code, etc.]

---
*Reviewed by 4 parallel agents with confidence threshold ≥80*
```

**If no issues with confidence ≥80:**
```markdown
## Code Review

**Summary:** Changes look good. No significant issues found.

### What's Good ✓
[Mention positive aspects of the code]

✅ **Approved** - No blocking issues found.

---
*Reviewed by 4 parallel agents with confidence threshold ≥80*
```

## Review Checklist Reference

For manual verification, agents should consider:

### Correctness
- Does the code do what it's supposed to do?
- Are there edge cases not handled?
- Are there potential bugs or logic errors?
- Are error cases handled appropriately?

### Security
- Any hardcoded secrets or credentials?
- Input validation present where needed?
- SQL injection, XSS, or other vulnerability risks?
- Proper authentication/authorization checks?

### Performance
- Any obvious performance issues (N+1 queries, unnecessary loops)?
- Large data structures handled efficiently?
- Appropriate use of caching if needed?

### Code Quality
- Is the code readable and well-organized?
- Are names clear and descriptive?
- Is there unnecessary complexity or duplication?
- Does it follow the project's existing patterns?

### Testing
- Are there tests for the new code?
- Do existing tests still pass?
- Are edge cases tested?

## False Positives to Ignore

Do NOT report these (they inflate noise):
- Pre-existing issues not introduced by this PR
- Issues that linters/formatters will catch
- Code that "looks wrong" but is intentional (check git blame)
- General style preferences not in CLAUDE.md
- Hypothetical future issues
- Lines with `// eslint-disable` or similar ignore comments
- Auto-generated code

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
