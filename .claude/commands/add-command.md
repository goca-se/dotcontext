# Add Command

Create a new Claude Code slash command for this project.

**Usage:** `/add-command [name]`

## Process

### 1. Get Command Details

If `$ARGUMENTS` is empty, **use AskUserQuestion tool** to ask:
- "What should this command do?"

**Then ask:**
- "What name should the command have?" (will be used as `/[name]`)
- "Should this command ask clarifying questions before executing?"
- "What should the output look like?"

### 2. Analyze Similar Commands

Read existing commands in `.claude/commands/` to understand:
- The project's command style
- Common patterns used
- Level of detail expected

### 3. Create Command File

Create `.claude/commands/[name].md`:

```markdown
# [Command Name]

[Brief description of what this command does]

**Usage:** `/[name] [arguments if any]`

## Process

### 1. [First Step]

[What the AI should do]

### 2. [Second Step]

[What the AI should do]

### 3. [Third Step]

[What the AI should do]

## Before Executing

[If the command should ask questions first]

**Use AskUserQuestion tool** to clarify:
- [Question 1]
- [Question 2]

## Guidelines

- [Guideline 1]
- [Guideline 2]
- [Guideline 3]

## Output

[Expected output format]

```
[Example output]
```
```

### 4. Test Instructions

Provide instructions for the user to test the new command.

## Output

```
Created: .claude/commands/[name].md

Command: /[name]
Purpose: [brief description]

Test it now with:
  /[name] [example arguments]
```

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
