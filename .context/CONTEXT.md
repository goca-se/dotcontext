# Domain Context

## Overview

**dotcontext** helps development teams create structured documentation for AI assistants (particularly Claude Code). It solves the problem of AI assistants lacking project-specific context by scaffolding a standardized structure of files that document architecture, decisions, recurring patterns, and feature planning.

**Users:** Developers and teams who use AI coding assistants and want to provide them with project context.

**Problem solved:** AI assistants work better when they understand the project's architecture, conventions, and past decisions. dotcontext creates and manages this context documentation.

## Domain

### Core Entities

| Entity | Responsibility |
|--------|----------------|
| `CLAUDE.md` | Root-level project context: stack, commands, critical rules, architecture overview |
| `.context/CONTEXT.md` | Domain knowledge: entities, flows, integrations, glossary |
| `ADR (Architectural Decision Record)` | Documents a significant architectural decision with context, alternatives, and consequences |
| `Skill` | Step-by-step guide for a recurring pattern or task in the codebase |
| `PRP (Product Requirements Prompt)` | Structured feature specification with implementation plan and phases |
| `Command` | Custom Claude Code slash command (markdown file in `.claude/commands/`) |

### Modules/Packages

```
dotcontext/
├── dotcontext           # Main CLI executable (all commands)
├── install.sh           # Installation script
├── scripts/
│   ├── notify.sh        # Cross-platform notification system
│   └── setup-hooks.sh   # Claude Code hook configuration
├── templates/           # Template files downloaded during init
│   ├── CLAUDE.md
│   └── .context/
│       ├── CONTEXT.md
│       ├── decisions/
│       ├── skills/
│       └── prp/
└── .claude/commands/    # Slash commands for Claude Code
    ├── setup-context.md
    ├── generate-prp.md
    ├── execute-prp.md
    └── code-review.md
```

## Main Flows

### Initialization Flow

```
User runs: dotcontext init
    │
    ├─→ Check if already initialized (warn if .context/ exists)
    │
    ├─→ Prompt for project name (or use --name flag)
    │
    ├─→ Download templates from GitHub
    │   └── templates/CLAUDE.md, templates/.context/*
    │
    ├─→ Create directory structure
    │   └── CLAUDE.md, .context/, .claude/commands/
    │
    ├─→ Setup notifications in ~/.claude/settings.json
    │   └── Hooks for Notification and Stop events
    │
    └─→ Auto-run Claude Code with /setup-context (unless --no-setup)
        └── Opens interactive Claude session analyzing the project
```

### Feature Development Flow (PRP Workflow)

```
User runs: /generate-prp "Add user authentication"
    │
    ├─→ AI asks 10 clarifying questions
    │
    ├─→ AI analyzes codebase, skills, decisions
    │
    └─→ Creates .context/prp/generated/YYYYMMDD-user-auth.md

User runs: /execute-prp user-auth
    │
    ├─→ AI reads full PRP
    │
    ├─→ Offers worktree isolation (parallel development)
    │
    ├─→ Creates feature branch
    │
    └─→ Implements phase by phase
        └── Runs tests/linting after each phase
```

### Update Flow

```
User runs: dotcontext update
    │
    ├─→ Check current version vs GitHub releases
    │
    ├─→ Download new version to temp file
    │
    ├─→ Validate download (check for shebang)
    │
    └─→ Replace /usr/local/bin/dotcontext
```

## External Integrations

| System | Type | Description |
|--------|------|-------------|
| GitHub API | REST API | Check latest releases for updates, download templates |
| Claude Code | Tool Integration | Slash commands integrate with AskUserQuestion, file tools |
| OS Notification System | Native | macOS (osascript), Linux (notify-send), Windows (PowerShell) |

## Glossary

| Term | Definition |
|------|------------|
| **ADR** | Architectural Decision Record - documents why a significant technical decision was made |
| **Skill** | A documented recurring pattern with step-by-step instructions |
| **PRP** | Product Requirements Prompt - structured feature specification for AI implementation |
| **Slash command** | A `/command` that triggers a markdown-defined workflow in Claude Code |
| **Worktree** | Git feature allowing multiple working directories from one repo, used for parallel feature development |
| **Decision Compliance** | The system of checking ADRs before making changes that might conflict with existing decisions |
| **Hook** | Claude Code event handler that runs shell commands on events like Notification or Stop |
