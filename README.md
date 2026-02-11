<p align="center">
  <img src="assets/dotcontext.svg" alt="dotcontext logo" width="150">
</p>

<h1 align="center">dotcontext</h1>

<p align="center">
  <em>Scaffold AI context structure for your codebase</em>
</p>

<p align="center">
  <a href="https://github.com/goca-se/dotcontext/releases/latest"><img src="https://img.shields.io/github/v/release/goca-se/dotcontext" alt="Release"></a>
  <a href="https://github.com/goca-se/dotcontext/blob/main/LICENSE"><img src="https://img.shields.io/github/license/goca-se/dotcontext" alt="License"></a>
</p>

`dotcontext` creates a standardized structure for AI assistants to understand your project. It generates templates and a Claude Code command that automatically analyzes and documents your codebase.

<p align="center">
  <img src="assets/demo-quickstart.gif" alt="dotcontext quick start demo" width="700">
</p>

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

This creates the context structure, downloads templates, and **automatically opens Claude Code running `/setup-context`** to analyze and populate your project's context files.

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
  • .context/skills/bug-reproduction/SKILL.md (user-managed — skipped)

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

The generated `CLAUDE.md` includes instructions for AI assistants to **respect architectural decisions**.

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
├── CLAUDE.md                    # Quick reference + decision compliance rules
├── .context/
│   ├── CONTEXT.md               # Domain knowledge
│   ├── decisions/               # ADRs (versioned)
│   ├── discoveries/             # Deep context analysis outputs
│   ├── bugs/                    # Bug fix reports
│   ├── skills/                  # Step-by-step guides
│   │   └── bug-reproduction/    # Bug reproduction patterns
│   └── prp/                     # Feature planning docs
│       ├── templates/
│       └── generated/
└── .claude/
    └── commands/
        ├── setup-context.md          # Auto-setup command
        ├── code-review.md            # Code review command
        ├── generate-prp.md           # Generate feature PRPs
        ├── execute-prp.md            # Execute PRPs step-by-step
        ├── create-pr.md              # Create PRs with diagrams
        ├── pr-comment.md             # Comment on PRs
        ├── add-decision.md           # Add ADR interactively
        ├── add-skill.md              # Add skill interactively
        ├── add-command.md            # Add custom command
        ├── deep-context.md           # Multi-agent business rule discovery
        └── fix-bug.md               # Test-driven bug fixing
```

Additionally, `dotcontext init` configures **native OS notifications** in `~/.claude/`:

```
~/.claude/
├── scripts/
│   └── notify.sh          # Cross-platform notification script
└── settings.json          # Hooks for Notification and Stop events
```

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
| `dotcontext --help`                    | Show help                                      |
| `dotcontext --version`                 | Show version                                   |

### Claude Code Commands

| Command                      | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `/setup-context`             | Analyze codebase and populate context          |
| `/generate-prp [feature]`    | Plan a new feature with clarifying questions   |
| `/execute-prp [name]`        | Implement a planned feature                    |
| `/code-review [--comment]`   | Multi-agent code review with confidence scoring |
| `/create-pr`                 | Create PR with auto-detected architecture diagrams |
| `/pr-comment [PR] [message]` | Add comments to PRs with optional diagrams     |
| `/deep-context [query]`      | Multi-agent business rule discovery across repos |
| `/fix-bug [description]`    | Test-driven bug fixing with parallel agents    |
| `/add-decision`              | Add and populate an ADR interactively          |
| `/add-skill`                 | Add and populate a skill guide                 |
| `/add-command`               | Create a custom slash command                  |

## Built-in Slash Commands

### `/setup-context`

Analyzes your codebase and populates context files:

- Fills `CLAUDE.md` with stack, commands, rules
- Documents domain in `.context/CONTEXT.md`
- Creates ADRs for existing architectural decisions
- Sets up skills for recurring patterns
- Adds example files showing well-structured code

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

- **Asks 10 clarifying questions** before generating (mandatory)
- Analyzes codebase patterns and existing architecture
- Consults skills and decisions for consistency
- Creates structured implementation plan with phases
- Saves to `.context/prp/generated/`

The clarifying questions ensure the PRP captures the right scope, constraints, and edge cases before any code is written.

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

Multi-agent business rule discovery across the current repository and a related one:

**Architecture:**
- Orchestrates **5 specialized agents**:
  - Agent 1: Compliance & Scope Guardian — defines search boundaries
  - Agent 2: Primary Explorer — deep searches main repo for business rules
  - Agent 3: Cross-Repo Explorer — searches related repository
  - Agent 4: Cross-Repo Validator — compares rules between repos
  - Agent 5: Reviewer — unifies findings, filters low-confidence items
- **Phased execution**: Agents 1-3 run in parallel, Agent 4 waits for 2+3, Agent 5 waits for all
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

`dotcontext init` automatically configures native OS notifications for Claude Code:

| Event | When | Sound (macOS) |
|-------|------|---------------|
| **Notification** | Claude needs attention (question, permission) | Purr |
| **Stop** | Claude finished processing | Funk |

**Supported platforms:**

- **macOS**: Native notifications via `osascript`
- **Linux**: `notify-send` + `paplay`/`aplay`
- **Windows/WSL**: PowerShell toast notifications

No additional dependencies required.

## Requirements

- Bash 3.2+
- `curl` or `wget`

## Uninstall

```bash
rm /usr/local/bin/dotcontext
```
