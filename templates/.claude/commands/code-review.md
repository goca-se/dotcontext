# Code Review

Review the code changes and provide actionable feedback.

## Instructions

You are performing a code review. Analyze the changes thoroughly and provide constructive feedback.

**Review principles:**
- Focus on correctness, maintainability, and clarity
- Be specific - reference exact lines and files
- Suggest concrete improvements, not vague criticisms
- Acknowledge good patterns when you see them
- Prioritize issues by severity (critical > major > minor > nit)

## Review Checklist

### 1. Correctness
- Does the code do what it's supposed to do?
- Are there edge cases not handled?
- Are there potential bugs or logic errors?
- Are error cases handled appropriately?

### 2. Security
- Any hardcoded secrets or credentials?
- Input validation present where needed?
- SQL injection, XSS, or other vulnerability risks?
- Proper authentication/authorization checks?

### 3. Performance
- Any obvious performance issues (N+1 queries, unnecessary loops)?
- Large data structures handled efficiently?
- Appropriate use of caching if needed?

### 4. Code Quality
- Is the code readable and well-organized?
- Are names clear and descriptive?
- Is there unnecessary complexity or duplication?
- Does it follow the project's existing patterns?

### 5. Testing
- Are there tests for the new code?
- Do existing tests still pass?
- Are edge cases tested?

## Output Format

Structure your review as:

```
## Summary
[1-2 sentence overview of the changes and overall assessment]

## Critical Issues
[Must be fixed before merging]

## Suggestions
[Improvements that would make the code better]

## Minor/Nits
[Small style or preference issues]

## What's Good
[Positive aspects worth acknowledging]
```

If reviewing a PR or diff, use the format:
- `file.ts:42` - [Issue description]

If no significant issues found, say so clearly and approve the changes.
