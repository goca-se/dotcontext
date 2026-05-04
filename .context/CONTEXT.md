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
| `ADR (Architectural Decision Record)` | Documents a significant architectural decision (schema 1.0 legacy or 2.0 going forward) |
| `Skill` | Step-by-step guide for a recurring pattern or task in the codebase |
| `PRP (Product Requirements Prompt)` | Structured feature specification with implementation plan and phases |
| `Command` | Custom Claude Code slash command (markdown file in `.claude/commands/`) |
| `Discovery` | Output document from deep context analysis with business rules and cross-repo validation |
| `Bug Report` | Structured report from `/fix-bug` with root cause, reproduction test, and fix details |
| `Manifest item` | A marketplace catalog entry (`command-bundle`, `skill`, `mcp`, `external-cli`, `hook`, `script`) — see `marketplace/manifest.json` |
| `Bundle` | An atomic install unit: a manifest item plus its transitive `depends_on` graph (ADR-017) |
| `Lockfile entry` | Record of what's installed, where, and at what version — `.context/.dotcontext-state.json` (local) or `~/.dotcontext/state.json` (global) (ADR-016) |

### Modules/Packages

High-level map (canonical tree lives in [Architecture > Directory Structure](#directory-structure) below):

| Path | Role |
|------|------|
| `dotcontext` | Built CLI executable (~95 KB, bundled from `src/` via `make build`) |
| `src/` | Modular source: `core/`, `lib/{ui,marketplace,install}/`, `commands/`, `setup/`, `header.sh`, `main.sh` |
| `marketplace/` | Layer 2 catalog: `manifest.json` (16 items, 11 starter pack) + `manifest.schema.json` |
| `templates/` | Files served to user projects: `CLAUDE.md`, `.context/`, `.claude/commands/` (12), `.claude/agents/` (12 across code-review/fix-bug/deep-context), `.claude/scripts/statusline.sh`, `.claude/skills/` (3 seed: bug-reproduction, batch-operations, git-platform) |
| `tests/` | `marketplace/{smoke,migrate_smoke}.sh`, `ui/{syntax_check,demo}.sh`, `sandbox.sh` |
| `scripts/` | Repo tooling: `notify.sh`, `validate-manifest.sh` |
| `docs/` | `MIGRATION.md` (v0.14 → v0.15 upgrade guide) |
| `install.sh` | curl-based installer |
| `.claude/commands/` | This repo's own slash commands (Layer 1 + maintainer-only `release.md`) |

## Architecture

### System Overview

dotcontext is a single-executable CLI tool (Bash 3.2+) distributed as one script file. Source code is modular (`src/`) and bundled via `make build` into the single `dotcontext` executable (~1266 lines). It follows a command-router pattern where all commands are functions dispatched via a case statement. It integrates with Claude Code through markdown-based slash commands that orchestrate multi-agent workflows.

### Directory Structure

```
dotcontext/
├── dotcontext              # Built CLI executable (bundled from src/, ~90 KB)
├── src/                    # Modular source code (bundled via make build)
│   ├── header.sh           # Shebang, set -e, VERSION, repo constants
│   ├── main.sh             # Command router (no-args → cmd_browse)
│   ├── core/               # Shared utilities (colors, icons, ui, spinner, utils)
│   ├── lib/                # Marketplace + TUI primitives (ADR-014, ADR-015)
│   │   ├── ui/             # menu_paginated, multi_select, detail_pane, confirm, spinner_alt, tabs
│   │   ├── marketplace/    # manifest, lockfile, scope, bundle, migrate
│   │   └── install/        # command, skill, script, mcp, hook, cli, dispatch
│   ├── commands/           # CLI command implementations
│   │   ├── init.sh         # dotcontext init — Layer 1 only
│   │   ├── update.sh       # dotcontext update — Layer 1 + auto-registration
│   │   ├── help.sh         # dotcontext --help
│   │   └── browse.sh       # marketplace TUI (no-args, internal entry)
│   └── setup/              # Post-init helpers (notifications, mcp)
├── marketplace/
│   ├── manifest.json       # Catalog of Layer 2 items (16 items, 11 in starter pack)
│   └── manifest.schema.json
├── install.sh              # curl-based installer
├── scripts/
│   ├── validate-manifest.sh   # make validate-manifest
│   ├── notify.sh           # Cross-platform notification
│   └── setup-hooks.sh
├── templates/              # Files downloaded during init / installed by marketplace
│   ├── CLAUDE.md
│   ├── .context/           # Context skeleton (CONTEXT.md, decisions/, prp/, etc.)
│   └── .claude/            # commands/, agents/, skills/, scripts/
├── tests/
│   ├── ui/                 # syntax_check + composed demo for lib/ui
│   └── marketplace/        # smoke tests for marketplace + migration
└── docs/MIGRATION.md       # v0.14 → v0.15 upgrade guide
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

Bash smoke tests under `tests/`, no unit-test framework. `make check` runs `validate-manifest.sh` (manifest schema) and `tests/ui/syntax_check.sh` (UI module syntax). `tests/marketplace/{smoke,migrate_smoke}.sh` exercise install + auto-registration end-to-end against a sandbox project. Health-check validation (formerly `dotcontext doctor`, removed in v0.15) now lives in the marketplace TUI's **Status** tab.

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
    ├─→ Setup notifications in .claude/settings.json (project-local)
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
    ├─→ Phase 2: Template Update (if .context/ exists)
    │   ├── Download managed templates (commands)
    │   ├── Download seed templates (skills, READMEs)
    │   ├── Categorize: new (+), modified (~), unchanged (=), user-managed (•)
    │   ├── Managed: offer to update modified files
    │   ├── Seed: only add if missing, never overwrite
    │   └── Show Terraform-style preview
    │
    └─→ Phase 3: Auto-migration (ADR-018, runs once per install)
        ├── Detect pre-marketplace installs by scanning .claude/commands/
        ├── Register existing items in the lockfile (.context/.dotcontext-state.json)
        └── Mark migration complete; skipped on subsequent updates
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

### Marketplace Install Flow

```
User runs: dotcontext   (no args → cmd_browse)
    │
    ├─→ Load manifest.json (validates schema)
    │
    ├─→ Open TUI tabs: Browse · Installed · Status
    │
    ├─→ Browse tab: pick item(s) or `p` to mark the 11-item starter pack
    │   ├── space toggles selection
    │   ├── g/l switches scope (global ~/.claude/ vs local .context/)
    │   └── i triggers install
    │
    ├─→ Bundle resolver (ADR-017): expand item + transitive depends_on
    │
    ├─→ Per-file dispatch by type (ADR-014):
    │   ├── command  → templates/.claude/commands/*.md       → .claude/commands/
    │   ├── skill    → templates/.claude/skills/*/SKILL.md   → .claude/skills/
    │   ├── script   → templates/.claude/scripts/*.sh        → .claude/scripts/
    │   ├── hook     → merge into .claude/settings.json
    │   ├── mcp      → merge into .mcp.json (or ~/.claude.json for global)
    │   └── cli      → external installer (gh, glab) + auth check
    │
    ├─→ Record entry in lockfile (ADR-016)
    │   ├── local:  .context/.dotcontext-state.json
    │   └── global: ~/.dotcontext/state.json
    │
    └─→ Status tab: re-runs health checks (Layer 1 sanity, MCP auth, CLI install state)
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
