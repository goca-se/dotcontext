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

### Update CLI

```bash
dotcontext update              # Update CLI to latest version
```

### Update templates

When new templates or commands are added to dotcontext, update your project:

```bash
dotcontext update --templates              # Preview + prompt before updating
dotcontext update --templates --dry-run    # Preview only, no changes
dotcontext update --templates --yes        # Update without prompting
```

**Terraform-style preview:**

```
Checking templates...

  + .claude/commands/new-command.md (new)
  ~ .claude/commands/code-review.md (modified)
  = .context/prp/templates/feature.md (unchanged)

Summary: 1 to add, 1 to update, 1 unchanged

Update 1 existing file(s)? [y/N/d] (y=yes, N=no, d=show diffs)
```

**Safe by default:**

- Shows exactly what will change before doing anything
- Default action (`N`) only adds new files, never overwrites
- Press `d` to see diffs before deciding
- Never touches user content (`CONTEXT.md`, `CLAUDE.md`, your ADRs/skills)

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
│   ├── skills/                  # Step-by-step guides
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
        └── add-command.md            # Add custom command
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
| `dotcontext update`                    | Update CLI to latest version                   |
| `dotcontext update --templates`        | Preview and update templates (prompts first)   |
| `dotcontext update --templates --yes`  | Update templates without prompting             |
| `dotcontext update --templates --dry-run` | Preview changes only, no modifications      |
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
