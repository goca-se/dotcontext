<p align="center">
  <img src="assets/dotcontext.svg" alt="dotcontext logo" width="150">
</p>

<h1 align="center">dotcontext</h1>

<p align="center">
  <em>AI context toolkit for coding agents — Claude Code, Codex, opencode, Gemini, Copilot & Cursor</em>
</p>

<p align="center">
  <a href="https://github.com/goca-se/dotcontext/releases/latest"><img src="https://img.shields.io/github/v/release/goca-se/dotcontext" alt="Release"></a>
  <a href="https://github.com/goca-se/dotcontext/blob/main/LICENSE"><img src="https://img.shields.io/github/license/goca-se/dotcontext" alt="License"></a>
</p>

`dotcontext` is an AI context toolkit for coding agents — Claude Code, OpenAI Codex, opencode, Gemini CLI, GitHub Copilot, and Cursor. It provides commands, decisions, skills, and feature planning workflows that help AI assistants understand and work with your codebase.

<details>
<summary>See it in action</summary>

<p align="center">
  <img src="assets/demo-quickstart.gif" alt="dotcontext quick start demo" width="700">
</p>

</details>

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/goca-se/dotcontext/main/install.sh | bash
```

Or manually:

```bash
curl -sSL https://raw.githubusercontent.com/goca-se/dotcontext/main/dotcontext -o /usr/local/bin/dotcontext
chmod +x /usr/local/bin/dotcontext
```

## Usage

### Initialize a project

```bash
cd your-project
dotcontext init
```

This creates the context structure and downloads templates for the harness(es) you select. When **Claude Code** is among them, it **automatically opens Claude running `/setup-context`** to analyze and populate your project's context files; otherwise, edit `AGENTS.md` and `.context/CONTEXT.md` to describe your project.

**Options:**

```bash
dotcontext init --name "My Project"  # Set project name
dotcontext init --yes                # Skip prompts, use defaults
dotcontext init --no-setup           # Skip automatic /setup-context execution
```

### Update

```bash
dotcontext update                  # Update CLI + templates (if in a project)
dotcontext update --cli            # Only update CLI
dotcontext update --templates      # Only update templates
dotcontext update --dry-run        # Preview template changes only
dotcontext update --yes            # Update templates without prompting
```

**Terraform-style preview for templates:**

```
Checking templates...

  + .claude/commands/fix-bug.md (new)
  ~ .claude/commands/code-review.md (modified)
  = .claude/commands/setup-context.md (unchanged)
  • .claude/skills/bug-reproduction/SKILL.md (user-managed — skipped)

Summary: 1 to add, 1 to update, 8 unchanged, 1 user-managed

Update 1 existing file(s)? [y/N/d] (y=yes, N=no, d=show diffs)
```

**Safe by default:**

- CLI downloads from the release tag (not main branch) — no unreleased code
- Templates show exactly what will change before doing anything
- Default action (`N`) only adds new files, never overwrites
- Press `d` to see diffs before deciding
- **User-managed files** (skills, READMEs, PRP templates) are never overwritten — they're created once during init and then owned by you
- Never touches user content (`CONTEXT.md`, `CLAUDE.md`, your ADRs, bug reports, discoveries)

### Run the setup command

The setup command runs automatically after `dotcontext init`. To run it manually (e.g., after code changes):

```bash
claude
> /setup-context
```

<details>
<summary>See it in action</summary>

<img src="assets/demo-setup-context.gif" alt="setup-context demo" width="600">

</details>

## Decision Compliance

The generated `AGENTS.md` (the canonical instructions file) includes instructions for AI assistants to **respect architectural decisions**.

When you ask Claude Code to make a change that conflicts with an existing ADR, it will:

1. **Stop and inform you** which decision(s) would be affected
2. **Ask explicitly** if you want to:
   - Proceed and update the decision
   - Modify the approach to comply
   - Cancel the change
3. **If updating**, create a versioned ADR (marking old one as `Superseded`)

This ensures your architectural decisions stay synchronized with your code.

## What It Creates

```
your-project/
├── AGENTS.md                    # Canonical project instructions (read by Codex, opencode, Copilot, Cursor…)
├── CLAUDE.md                    # Thin @AGENTS.md import for Claude Code (always added for compatibility)
├── GEMINI.md                    # Thin @AGENTS.md import for Gemini CLI (added when Gemini is detected)
├── .context/
│   ├── CONTEXT.md               # Domain knowledge
│   ├── decisions/               # ADRs (versioned)
│   ├── discoveries/             # Deep context analysis outputs
│   ├── bugs/                    # Bug fix reports
│   └── prp/                     # Feature planning docs
│       ├── templates/
│       └── generated/
├── .mcp.json                    # MCP server config (Context7, Atlassian)
└── .claude/
    ├── commands/
    │   ├── setup-context.md          # Auto-setup command
    │   ├── code-review.md            # Code review command
    │   ├── commit.md                 # Smart commit command
    │   ├── generate-prp.md           # Generate feature PRPs
    │   ├── execute-prp.md            # Execute PRPs step-by-step
    │   ├── create-pr.md              # Create PRs with diagrams
    │   ├── pr-comment.md             # Comment on PRs
    │   ├── add-decision.md           # Add ADR interactively
    │   ├── add-skill.md              # Add skill interactively
    │   ├── add-command.md            # Add custom command
    │   ├── deep-context.md           # Structured codebase exploration
    │   └── fix-bug.md               # Test-driven bug fixing
    ├── agents/                       # Extracted agent prompts
    │   ├── code-review/              # 3 review agents
    │   ├── deep-context/             # 4 exploration agents
    │   └── fix-bug/                  # 5 bug-fix agents
    ├── skills/                       # Step-by-step guides (SKILL.md w/ name+description frontmatter)
    │   ├── bug-reproduction/         # Reproduce-before-fixing patterns
    │   ├── batch-operations/         # Safe multi-file changes
    │   ├── git-platform/             # Detect GitHub/GitLab/… before git CLI
    │   └── update-api-documentation/ # OpenAPI SSOT docs
    └── scripts/
        └── statusline.sh            # StatusLine: model, dir, git, ctx-usage bar, cost/time/lines
```

> Files are emitted per chosen harness (see [Multi-Agent Support](#multi-agent-support)): `AGENTS.md` and `.context/` are always written; the full `.claude/` tree and `CLAUDE.md` appear only when **Claude** is selected, `GEMINI.md` only for **Gemini**, and `.agents/skills/` only when a non-Claude agent is selected.

Additionally, `dotcontext init` configures:

- **MCP servers** in `.mcp.json` (optional, prompted during init):
  - [Context7](https://github.com/upstash/context7-mcp) — up-to-date library docs for LLMs
  - [Atlassian](https://mcp.atlassian.com) — Jira + Confluence via OAuth

- **Native OS notifications** in `.claude/` (project-local):

```
.claude/
├── scripts/
│   └── notify.sh          # Cross-platform notification script
└── settings.json          # Hooks for Notification and Stop events
```

## Multi-Agent Support

dotcontext targets six harnesses — **Claude Code, OpenAI Codex, opencode, Gemini CLI, GitHub Copilot, and Cursor** (IDE + `cursor-agent`). `init` only writes files for the harnesses you choose, so you never get junk (no `.claude/` in a Codex-only project):

```bash
dotcontext init                       # interactive: confirm each detected agent
dotcontext init --agents codex,cursor # explicit, non-interactive
dotcontext init --yes                 # all detected agents
```

What's shared vs per-harness (ADR-016, ADR-017):

| Layer | Coverage |
| --- | --- |
| **Instructions** — canonical `AGENTS.md` | Codex/opencode/Copilot/Cursor read it natively; Claude (`CLAUDE.md`) and Gemini (`GEMINI.md`) via `@AGENTS.md` import |
| **Skills** — shared `SKILL.md` | `.agents/skills/` (Codex/opencode/Gemini/Copilot/Cursor) mirrored to `.claude/skills/` (Claude) |
| **Hooks** — notification on finish | native config per harness (`.codex/`, `.gemini/`, `.github/hooks/`, `.cursor/`, opencode plugin); Claude also gets the tool-failure guard |
| **Commands / workflows** | Claude → `.claude/commands/`; opencode → `.opencode/command/`; Copilot → `.github/prompts/`; Gemini/Cursor/Codex → a `## Workflows` section in `AGENTS.md` |

`dotcontext update` migrates an existing single-file `CLAUDE.md` into the shared `AGENTS.md` (Claude keeps working via the import). Check `dotcontext --version --json` for the live capability/agent list.

## Commands Reference

### CLI Commands

| Command                                | Description                                    |
| -------------------------------------- | ---------------------------------------------- |
| `dotcontext init`                      | Initialize + auto-run /setup-context           |
| `dotcontext init --no-setup`           | Initialize without running setup               |
| `dotcontext update`                    | Update CLI + templates (if in a project)       |
| `dotcontext update --cli`              | Only update CLI                                |
| `dotcontext update --templates`        | Only update templates                          |
| `dotcontext update --yes`              | Update templates without prompting             |
| `dotcontext update --dry-run`          | Preview template changes only                  |
| `dotcontext doctor`                    | Check project setup health (+ flags available updates) |
| `dotcontext completion [bash\|zsh]`    | Generate shell tab completions                 |
| `dotcontext --help`                    | Show help                                      |
| `dotcontext --version [--features\|--json]` | Show version; `--features`/`--json` expose the capability handshake |

### Claude Code Commands

| Command                      | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `/setup-context`             | Analyze codebase and populate context          |
| `/generate-prp [feature]`    | Plan a new feature with clarifying questions   |
| `/execute-prp [name]`        | Implement a planned feature                    |
| `/code-review [--comment]`   | Multi-agent code review with confidence scoring |
| `/commit [--amend]`          | Smart commit with style-aware message generation |
| `/create-pr`                 | Create PR with auto-detected architecture diagrams |
| `/pr-comment [PR] [message]` | Add comments to PRs with optional diagrams     |
| `/deep-context [query]`      | Structured 4-step codebase exploration            |
| `/fix-bug [description]`    | Test-driven bug fixing with parallel agents    |
| `/add-decision`              | Add and populate an ADR interactively          |
| `/add-skill`                 | Add and populate a skill guide                 |
| `/add-command`               | Create a custom slash command                  |
| `/release`                   | Version bump and release                       |

## Built-in Slash Commands

### `/setup-context`

Analyzes your codebase and populates context files:

- Fills `CLAUDE.md` with stack, commands, rules
- Documents domain in `.context/CONTEXT.md`
- **Generates Architecture section** — system overview, directory structure, key dependencies, data flow
- **Detects coding conventions** — adaptive sampling (5-20 files based on project size) across 6 categories: naming patterns, error handling, testing style, import organization, state management, API response format
- Creates ADRs for existing architectural decisions
- Sets up skills for recurring patterns

### `/code-review [--comment]`

Multi-agent code review inspired by [Claude Code's official plugin](https://github.com/anthropics/claude-code/tree/main/plugins/code-review):

**Architecture:**
- Launches **4 parallel agents** for independent analysis:
  - 2x CLAUDE.md compliance checkers (redundancy)
  - 1x Bug detector (logic errors, edge cases, type mismatches)
  - 1x Security & history analyzer (vulnerabilities + git blame patterns)
- **Confidence scoring** (0-100) filters false positives (threshold ≥80)
- Automatic context gathering (CLAUDE.md files + PR diff)

**Usage:**
```bash
/code-review           # Review to terminal
/code-review --comment # Post review as PR comment
```

**Pre-flight checks** (auto-skips):
- Closed or merged PRs
- Draft PRs
- PRs already reviewed by this tool
- Trivial changes (whitespace only)

**Review categories:**
- Correctness and edge cases
- Security vulnerabilities (OWASP top 10)
- Performance issues
- Code quality and patterns
- CLAUDE.md rule violations

### `/generate-prp <feature description>`

Generates a Product Requirements Prompt for a new feature:

- **Runs a clarity assessment** and asks N targeted questions (0..N) — only the ones that genuinely unblock ambiguity
- Analyzes codebase patterns and existing architecture
- Consults skills and decisions for consistency
- Pauses at a **Validation Gate** with a parallel Haiku auto-validation subagent before locking the implementation plan
- Creates structured implementation plan with phases, a final e2e verification phase, and a Parallelism Map for `/execute-prp`
- Saves to `.context/prp/generated/`

Example:

```
> /generate-prp user authentication with OAuth
```

<details>
<summary>See it in action</summary>

<img src="assets/demo-generate-prp.gif" alt="generate-prp demo" width="600">

</details>

### `/execute-prp <prp-name>`

Executes an existing PRP step-by-step:

- Reads the full PRP
- Checks prerequisites
- **Offers worktree isolation** for parallel development
- Implements in defined order
- Validates each phase (tests, linting)
- Stops on errors, fixes before continuing

#### Worktree Isolation

Before starting, the command asks if you want to create an isolated git worktree. This allows you to:

- Work on multiple features/fixes simultaneously
- Switch tasks without stashing or losing context
- Keep your main workspace clean

Branch types are automatically detected from PRP content:

| Type | Use case |
|------|----------|
| `feature/` | New functionality |
| `bugfix/` | Bug corrections |
| `hotfix/` | Urgent production fixes |
| `chore/` | Maintenance, refactoring |
| `experiment/` | Spikes, POCs |

Example:

```
> /execute-prp 20260129-user-auth

# Creates: ../your-project-user-auth (branch: feature/user-auth)
```

<details>
<summary>See it in action</summary>

<img src="assets/demo-execute-prp.gif" alt="execute-prp demo" width="600">

</details>

### `/create-pr`

Create well-structured pull requests with automatic architecture diagram detection:

- Analyzes all commits since branching from main
- Generates appropriate PR title and description
- **Auto-detects architectural changes** and suggests Mermaid diagrams:
  - New services/components → flowchart
  - API changes → sequence diagram
  - Data flow changes → flowchart
  - Database changes → ER diagram
- Pushes branch with confirmation if not on remote
- Respects existing PR templates (`.github/PULL_REQUEST_TEMPLATE.md`)

Example:

```
> /create-pr

# Analyzes changes, detects new API endpoint
# Generates PR with sequence diagram showing request flow
```

### `/pr-comment [PR] [message]`

Add comments to existing pull requests:

- **Comment types:**
  - General comment - conversation thread
  - Review comment - formal review
  - Diagram explanation - architecture with Mermaid
  - Status update - progress tracking

- Auto-detects PR from current branch if not specified
- Generates Mermaid diagrams when discussing architecture
- Integrates with `/code-review` for follow-up

Example:

```
> /pr-comment add diagram explaining the new auth flow
> /pr-comment 123 LGTM, tested locally
> /pr-comment update status - frontend complete
```

### `/deep-context [query]`

Structured 4-step codebase exploration with specialized agents:

**Architecture:**
- Follows a **structured progression** from high-level to detailed:
  - Step 1: **Overview Agent** — architecture summary, key files, entry points
  - Step 2: **Subsystem Agent** — module map, interdependencies, boundaries
  - Step 3: **Drill Agent** — targeted deep-dive into relevant areas
  - Step 4: **Data Flow Agent** — trace information movement through the system
- **Phased execution**: Steps 1+2 run in parallel, Steps 3+4 run sequentially (each builds on prior outputs)
- **Confidence filtering**: findings below 50% are auto-removed

**Features:**
- Auto-detects related repos from `.context/CONTEXT.md` external integrations
- `--repo` flag for manual repo specification (local path or git URL)
- `--cache` flag to reference previous discoveries
- Every finding backed by `file:line` references (no fabrication)
- Output saved to `.context/discoveries/`

**Usage:**
```
> /deep-context "checkout flow"
> /deep-context "payment rules" --repo ~/path/to/api
> /deep-context "order processing" --cache
```

### `/fix-bug [description]`

Test-driven bug fixing with parallel subagents:

**Architecture:**
- **Phase 1 — Investigation**: Agent analyzes the bug, identifies root cause, writes a failing test
- **Phase 2 — Parallel Fixes**: N agents (default 3) attempt fixes with diverse strategies:
  - Conservative (minimal diff)
  - Minimal change (surgical, exact lines)
  - Refactor (fix + improve surrounding code)
- **Phase 3 — Review**: Reviewer agent selects best fix or combines multiple successful fixes
- All agents run to completion (best fix, not just first fix)

**Features:**
- Zero questions — goes straight from description to investigation
- Test-first: writes a failing test before any fix attempt
- `--issue N` to include GitHub issue context
- `--pr N` to include PR context
- `--agents N` to configure parallel fix agents
- Bug report saved to `.context/bugs/`
- Includes `bug-reproduction` skill template for project-specific patterns

**Usage:**
```
> /fix-bug "login fails with empty password"
> /fix-bug "checkout timeout" --issue 42
> /fix-bug "regression in search" --pr 123 --agents 5
```

### `/add-decision [title]`

Interactively create and populate an Architectural Decision Record:

- Asks clarifying questions about context and alternatives
- Auto-numbers the ADR (001, 002, ...)
- Populates with structured content
- Updates the decisions index

### `/add-skill [name]`

Interactively create and populate a skill guide:

- Analyzes codebase for existing patterns
- Asks about use cases and anti-patterns
- Includes real code examples from your project
- Creates step-by-step documentation

### `/add-command [name]`

Create a custom Claude Code slash command:

- Asks about command purpose and behavior
- Generates command file with proper structure
- Immediately available as `/your-command`

## Notifications

`dotcontext init` automatically configures native OS notifications for each selected harness in its own hook config (`.claude/settings.json`, `.codex/hooks.json`, `.gemini/settings.json`, `.github/hooks/`, `.cursor/hooks.json`, or an opencode plugin). For Claude:

| Event | When | Sound (macOS) |
|-------|------|---------------|
| **Notification** | Claude needs attention (question, permission) | Purr |
| **Stop** | Claude finished processing | Funk |

**Supported platforms:**

- **macOS**: Native notifications via `osascript`
- **Linux**: `notify-send` + `paplay`/`aplay`
- **Windows/WSL**: PowerShell toast notifications

No additional dependencies required.

## Shell Completion

`dotcontext init` offers to wire this into your shell profile automatically. To set it up manually instead:

```bash
# Bash (add to ~/.bashrc)
eval "$(dotcontext completion bash)"

# Zsh (add to ~/.zshrc)
eval "$(dotcontext completion zsh)"
```

Completes subcommands (`init`, `update`, `doctor`, `completion`) and per-command options.

## Requirements

- Bash 3.2+
- `curl` or `wget`

## Uninstall

```bash
rm /usr/local/bin/dotcontext
```
