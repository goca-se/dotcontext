# PR Comment

Add comments to an existing pull request, optionally with Mermaid diagrams.

**Usage:** `/pr-comment [PR number or URL] [message]`

## Process

### 1. Identify the PR

If PR number/URL not provided, detect from current branch:

```bash
gh pr view --json number,url,title,state 2>/dev/null
```

If no PR found and not provided, **use AskUserQuestion** to ask for PR number.

### 2. Validate PR State

```bash
gh pr view <number> --json state,title,url
```

If PR is closed/merged, warn the user but allow commenting if they confirm.

### 3. Determine Comment Type

**Use AskUserQuestion** to clarify:
- Question: "What type of comment?"
- Options:
  - "General comment" - Add to PR conversation
  - "Review comment" - Start/add to a review
  - "Diagram explanation" - Add architectural diagram with explanation
  - "Summary update" - Add progress/status update

### 4. Generate Comment

Based on type, structure the comment appropriately:

**General comment:**
```markdown
<user's message or generated content>
```

**Review comment:**
```markdown
## Review Notes

<feedback organized by file/topic>

### Suggestions
- ...

### Questions
- ...
```

**Diagram explanation:**
```markdown
## Architecture Overview

<explanation of the diagram>

```mermaid
<diagram>
```

### Key Points
- <what the diagram shows>
- <important relationships>
```

**Summary update:**
```markdown
## Status Update

**Progress:** <percentage or status>

### Completed
- [x] <done items>

### In Progress
- [ ] <current work>

### Blocked/Needs Review
- [ ] <items needing attention>
```

### 5. Post Comment

For general/diagram/summary comments:
```bash
gh pr comment <number> --body "$(cat <<'EOF'
<comment content>
EOF
)"
```

For review comments, use:
```bash
gh pr review <number> --comment --body "$(cat <<'EOF'
<review content>
EOF
)"
```

### 6. Confirm Success

Output:
- Link to the comment
- Summary of what was posted

## Mermaid Diagram Detection

When the user asks for a diagram or mentions architecture/flow/structure:

1. Fetch the PR diff:
   ```bash
   gh pr diff <number>
   ```

2. Analyze changes and generate appropriate diagram type:
   - **Sequence diagram** - For API flows, request/response patterns
   - **Flowchart** - For logic flows, decision trees
   - **Class diagram** - For OOP structure changes
   - **ER diagram** - For database schema changes

3. Include diagram in comment with explanation

## Examples

**Simple comment:**
```
/pr-comment 123 LGTM, tested locally and works great
```

**Diagram for current PR:**
```
/pr-comment add architecture diagram showing the new auth flow
```

**Status update:**
```
/pr-comment 456 update status - frontend done, waiting on API changes
```

## Integration with /code-review

After running `/code-review --comment`, you can use `/pr-comment` to:
- Add follow-up comments
- Post resolution updates
- Add diagrams explaining fixes

## Important

- **Always use AskUserQuestion** for ambiguous requests
- Preview long comments before posting (ask user to confirm)
- Respect PR conversation context - read existing comments first if relevant
- Don't spam PRs with multiple comments - consolidate when possible
