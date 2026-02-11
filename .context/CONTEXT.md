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
| `Discovery` | Output document from deep context analysis with business rules and cross-repo validation |
| `Bug Report` | Structured report from `/fix-bug` with root cause, reproduction test, and fix details |

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
│       ├── discoveries/
│       ├── bugs/
│       ├── skills/
│       │   └── bug-reproduction/
│       └── prp/
└── .claude/commands/    # Slash commands for Claude Code
    ├── setup-context.md
    ├── generate-prp.md
    ├── execute-prp.md
    ├── code-review.md
    ├── deep-context.md
    └── fix-bug.md
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
    ├─→ Phase 1: CLI Update
    │   ├── Check latest release tag via GitHub API
    │   ├── Download from release tag (not main branch)
    │   ├── Validate download (check for shebang)
    │   └── Replace /usr/local/bin/dotcontext
    │
    └─→ Phase 2: Template Update (if .context/ exists)
        ├── Download managed templates (commands)
        ├── Download seed templates (skills, READMEs)
        ├── Categorize: new (+), modified (~), unchanged (=), user-managed (•)
        ├── Managed: offer to update modified files
        ├── Seed: only add if missing, never overwrite
        └── Show Terraform-style preview
```

### Deep Context Discovery Flow

```
User runs: /deep-context "checkout flow" --repo ~/api
    │
    ├─→ Parse arguments (query, --repo, --cache)
    │
    ├─→ Resolve related repo (auto-detect from CONTEXT.md or manual)
    │
    ├─→ Ask clarifying questions (scope, focus areas)
    │
    ├─→ Phase 1 (parallel): Launch 3 agents
    │   ├── Agent 1: Compliance & Scope Guardian
    │   ├── Agent 2: Primary Explorer (background)
    │   └── Agent 3: Cross-Repo Explorer (background)
    │
    ├─→ Phase 2 (sequential): Agent 4 validates cross-repo findings
    │
    ├─→ Phase 3 (sequential): Agent 5 unifies and produces final document
    │
    └─→ Save to .context/discoveries/YYYYMMDD-[slug].md
```

### Bug Fix Flow

```
User runs: /fix-bug "login fails with empty password" --issue 42
    │
    ├─→ Parse input (description, --issue, --pr, --agents)
    │
    ├─→ Gather bug context (description + GitHub issue/PR if provided)
    │
    ├─→ Phase 1 (sequential): Investigator agent
    │   ├── Search codebase for root cause
    │   ├── Write failing reproduction test
    │   └── Verify test FAILS (proves bug exists)
    │
    ├─→ Phase 2 (parallel): N fix agents (default 3)
    │   ├── Agent 1: Conservative fix (smallest diff)
    │   ├── Agent 2: Minimal change (surgical, exact lines)
    │   └── Agent 3: Refactor fix (improve surrounding code)
    │   └── ALL agents run to completion
    │
    ├─→ Phase 3 (sequential): Reviewer agent
    │   ├── Evaluate all fixes
    │   ├── Combine if >1 succeeded
    │   └── Run full test suite
    │
    └─→ Save report to .context/bugs/YYYYMMDD-[slug].md
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
