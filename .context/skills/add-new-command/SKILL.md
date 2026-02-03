# Skill: Add a New Claude Code Slash Command

## When to Use

Use this skill when you need to add a new interactive command that users can invoke with `/command-name` in Claude Code.

## Prerequisites

- Understanding of what the command should do
- Knowledge of Claude Code's tool system (AskUserQuestion, file tools, etc.)

## Steps

### 1. Create the command file

Create a new markdown file in `.claude/commands/`:

```bash
touch .claude/commands/my-command.md
```

The filename (without `.md`) becomes the slash command name.

### 2. Structure the command file

Follow this template structure:

```markdown
# Command Name

Brief description of what this command does.

## Instructions

Detailed instructions for Claude on how to execute this command.

**Important guidelines:**
- List specific behaviors
- Reference which tools to use
- Mention any context files to check

## Tasks

### 1. First Step

Description of what to do first.

### 2. Second Step

Description of what to do next.

## Output

Describe what the command should produce when complete.
```

### 3. Include AskUserQuestion usage

Per ADR-005, all commands should use AskUserQuestion for clarification:

```markdown
**Important:** Use the AskUserQuestion tool to clarify:
- [Question 1]
- [Question 2]
```

### 4. Reference context files

Commands should check relevant context:

```markdown
Before proceeding:
- Check `.context/decisions/` for related ADRs
- Consult `.context/skills/` for patterns to follow
```

### 5. Test the command

In Claude Code, run `/my-command` to verify it works as expected.

## Anti-Patterns

- **Don't make commands too broad** - Keep focused on one task
- **Don't skip AskUserQuestion** - Always clarify before significant work
- **Don't hardcode paths** - Use relative paths from project root
- **Don't ignore existing patterns** - Check skills/ and decisions/ first

## Example

See `.claude/commands/code-review.md` for a well-structured command that:
- Has clear instructions
- Uses a checklist for thoroughness
- Provides specific output format
- References exact file locations

## Related

- ADR-004: Claude Code integration
- ADR-005: AskUserQuestion requirement
