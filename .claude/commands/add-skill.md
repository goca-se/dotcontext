# Add Skill

Create and populate a new skill guide for recurring tasks.

**Usage:** `/add-skill [name or topic]`

## Process

### 1. Get Skill Topic

If `$ARGUMENTS` is empty, **use AskUserQuestion tool** to ask:
- "What task or pattern should this skill document?"

### 2. Analyze Codebase

Search the codebase to find:
- Existing patterns related to this skill
- Code examples that demonstrate the pattern
- Common files/modules involved

### 3. Gather Context

**Use AskUserQuestion tool** to ask 2-3 clarifying questions:
- When should developers use this pattern?
- Are there any anti-patterns or common mistakes to avoid?
- Any project-specific conventions for this task?

### 4. Create Skill Structure

```bash
mkdir -p .context/skills/[skill-slug]
```

### 5. Populate SKILL.md

Create `.context/skills/[skill-slug]/SKILL.md`:

```markdown
# Skill: [Name]

## When to Use

- [Situation 1 - based on analysis]
- [Situation 2]
- [Situation 3]

## Step by Step

### 1. [First Step]

[Explanation]

```[language]
# Code example from this codebase
[actual code found in the project]
```

### 2. [Second Step]

[Explanation]

```[language]
[code example]
```

### 3. [Third Step]

[Explanation]

```[language]
[code example]
```

## Anti-Patterns

**Don't:**
- [Bad practice 1 - why it's bad]
- [Bad practice 2 - why it's bad]

**Do:**
- [Good practice 1]
- [Good practice 2]

## Examples from This Codebase

### [Example 1 Name]

Located at: `[file path]`

```[language]
[relevant code snippet]
```

### [Example 2 Name]

Located at: `[file path]`

```[language]
[relevant code snippet]
```

## Related

- [Link to related ADR if applicable]
- [Link to related skill if applicable]
```

## Output

```
Created: .context/skills/[slug]/SKILL.md

Skill: [Name]

Steps documented: X
Examples included: X from codebase
Anti-patterns: X identified
```

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
