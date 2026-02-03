# Skills

Skills are step-by-step guides for recurring tasks in this project.

## Structure

```
skills/
└── [skill-name]/
    └── SKILL.md
```

## When to Create a Skill

- Task follows a specific pattern in this project
- Multiple steps that are easy to forget
- Anti-patterns that should be avoided
- Onboarding material for new contributors

## Template

```markdown
# Skill: [Name]

## When to Use

- [Situation 1]
- [Situation 2]

## Step by Step

### 1. [First Step]

\`\`\`bash
# commands or code
\`\`\`

### 2. [Second Step]

\`\`\`bash
# commands or code
\`\`\`

## Anti-Patterns

❌ **Don't:**
- [Bad practice]

✅ **Do:**
- [Good practice]
```

## Adding Skills

In Claude Code, use the interactive command:
```
/add-skill
```

This will ask clarifying questions and populate the skill with context.
