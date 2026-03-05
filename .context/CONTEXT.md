# Domain Context

## Overview

**dotcontext** is an AI context toolkit for Claude Code. It provides commands, decisions, skills, and feature planning workflows that help AI assistants understand and work with your codebase.

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
│   ├── .context/
│   │   ├── CONTEXT.md
│   │   ├── decisions/
│   │   ├── discoveries/
│   │   ├── bugs/
│   │   └── prp/
│   └── .claude/
│       ├── commands/    # 13 slash command templates
│       ├── agents/      # 12 agent prompt files (code-review, fix-bug, deep-context)
│       ├── scripts/     # StatusLine script
│       └── skills/      # Seed skills (bug-reproduction)
└── .claude/commands/    # This repo's slash commands (mirrors templates)
```

## Architecture

### System Overview

dotcontext is a single-executable CLI tool (Bash 3.2+) distributed as one script file. Source code is modular (`src/`) and bundled via `make build` into the single `dotcontext` executable (~1266 lines). It follows a command-router pattern where all commands are functions dispatched via a case statement. It integrates with Claude Code through markdown-based slash commands that orchestrate multi-agent workflows.

### Directory Structure

```
dotcontext/
├── dotcontext           # Built CLI executable (~1266 lines, bundled from src/)
├── src/                 # Modular source code (bundled via make build)
│   ├── header.sh        # Shebang, set -e, version, repo constants
│   ├── main.sh          # Command router (case statement)
│   ├── core/            # Shared utilities
│   │   ├── colors.sh    # ANSI color constants
│   │   ├── icons.sh     # Unicode icon constants
│   │   ├── ui.sh        # Print helpers (print_red, print_green, etc.)
│   │   ├── spinner.sh   # Braille animation spinner
│   │   └── utils.sh     # URL encoding, temp dir, download helpers
│   ├── commands/        # CLI command implementations
│   │   ├── init.sh      # dotcontext init (cmd_init)
│   │   ├── update.sh    # dotcontext update (cmd_update, ~423 lines)
│   │   ├── doctor.sh    # dotcontext doctor (cmd_doctor)
│   │   ├── help.sh      # dotcontext --help (cmd_help)
│   │   └── completion.sh # Shell tab completion (cmd_completion)
│   └── setup/           # Post-init setup helpers
│       ├── notifications.sh # Claude Code hook config for notifications
│       └── mcp.sh       # MCP server config (.mcp.json)
├── install.sh           # Installation script (curl-based)
├── scripts/
│   ├── notify.sh        # Cross-platform notification (macOS/Linux/Windows)
│   └── setup-hooks.sh   # Claude Code hook configuration
├── templates/           # Template files downloaded during init
│   ├── CLAUDE.md        # Root context template
│   ├── .context/        # Context structure templates
│   └── .claude/         # Commands, agents, skills, scripts
└── .claude/
    ├── commands/        # 13 slash command definitions
    ├── agents/          # 12 agent prompt files (3 subdirs)
    ├── scripts/         # StatusLine script
    └── skills/          # Seed skills (bug-reproduction, add-cli-subcommand, add-new-command)
```

### Key Dependencies

| Category | Dependency | Purpose |
|----------|-----------|---------|
| Runtime | Bash 3.2+ | POSIX-compatible script execution |
| Network | curl/wget | Template downloads from GitHub |
| Text Processing | sed, grep | File manipulation and search |
| JSON (optional) | jq | GitHub API response parsing |
| AI Integration | Claude Code | Slash command execution and agent orchestration |

### Data Flow

```
User → CLI (dotcontext) → GitHub API (templates/releases)
User → Claude Code → Slash Command (.md) → Agent Prompts (.md) → Task Tool (sub-agents)
Sub-agents → Grep/Glob/Read tools → Codebase → Structured findings → Orchestrator → Output file
```

## Conventions

### Naming Patterns

- **Files:** kebab-case for commands and agents (`setup-context.md`, `step1-overview.md`)
- **Bash functions:** snake_case with `cmd_` prefix for commands (`cmd_init`, `cmd_update`)
- **Variables:** UPPER_CASE for constants and environment vars, lower_case for locals
- **ADRs:** `NNN-kebab-case-title.md` numbering scheme

### Error Handling

Bash `set -e` with explicit error messages via `echo "Error: ..."` to stderr. Functions return non-zero exit codes on failure. No exception framework — fail-fast with descriptive messages.

### Testing Style

No automated test suite. Validation is manual/functional — run commands on sample projects and verify output. The `dotcontext doctor` command provides health-check validation.

### Import Organization

Not applicable (single Bash script). Agent prompt files use placeholder substitution (`{variable}`) for dynamic content injection.

### State Management

File-based state only. No database, no in-memory state between runs. Context persists in `.context/` directory structure. Agent communication passes through Task tool return values (no temp files per ADR-009).

### API Response Format

CLI output uses plain text with Unicode indicators (braille spinner, checkmarks). Discovery and bug report outputs use structured Markdown with tables.

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
    ├─→ Phase 1 (parallel): Steps 1 + 2
    │   ├── Step 1: Overview Agent — architecture summary, key files
    │   └── Step 2: Subsystem Agent — module map, interdependencies
    │
    ├─→ Phase 2 (sequential): Step 3
    │   └── Drill Agent — targeted deep-dive using Steps 1+2 output
    │
    ├─→ Phase 3 (sequential): Step 4
    │   └── Data Flow Agent — trace information movement
    │
    ├─→ Compile final document from all 4 agent outputs
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
