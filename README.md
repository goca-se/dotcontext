# dotcontext

> Scaffold AI context structure for your codebase

`dotcontext` creates a standardized structure for AI assistants to understand your project. It generates templates and a Claude Code command that automatically analyzes and documents your codebase.

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

This creates the context structure and downloads templates. You'll be prompted for a project name.

**Options:**
```bash
dotcontext init --name "My Project"  # Set project name
dotcontext init --yes                # Skip prompts, use defaults
dotcontext init -n "My App" -y       # Combine options
```

### Add context files

After initializing, add new context files as your project evolves:

```bash
# Add an Architectural Decision Record
dotcontext add decision

# Add a skill guide
dotcontext add skill

# Add a Product Requirements Prompt
dotcontext add prp

# Add a Claude Code slash command
dotcontext add command
```

### Run the setup command

After initialization, open Claude Code and run:

```bash
claude
> /setup-context
```

This analyzes your codebase and fills in the context files automatically.

## What It Creates

```
your-project/
├── CLAUDE.md                    # Quick reference for AI
├── .context/
│   ├── CONTEXT.md               # Domain knowledge
│   ├── decisions/               # ADRs
│   ├── skills/                  # Step-by-step guides
│   ├── examples/                # Reference code
│   └── prp/                     # Feature planning docs
└── .claude/
    └── commands/
        ├── setup-context.md     # Auto-setup command
        └── code-review.md       # Code review command
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `dotcontext init` | Initialize context structure |
| `dotcontext add decision` | Create an ADR (auto-numbered) |
| `dotcontext add skill` | Create a skill guide |
| `dotcontext add prp` | Create a feature planning doc |
| `dotcontext add command` | Create a Claude Code slash command |
| `dotcontext --help` | Show help |
| `dotcontext --version` | Show version |

## Built-in Slash Commands

### `/setup-context`

Analyzes your codebase and populates context files:
- Fills `CLAUDE.md` with stack, commands, rules
- Documents domain in `.context/CONTEXT.md`
- Creates ADRs for existing architectural decisions
- Sets up skills for common tasks

### `/code-review`

Performs structured code review checking:
- Correctness and edge cases
- Security vulnerabilities
- Performance issues
- Code quality and patterns
- Test coverage

## File Purposes

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Quick reference: stack, commands, critical rules |
| `.context/CONTEXT.md` | Domain: entities, flows, glossary |
| `.context/decisions/` | Why architectural choices were made |
| `.context/skills/` | How to do specific tasks |
| `.context/examples/` | Reference implementations |
| `.context/prp/` | Feature planning documents |

## Requirements

- Bash 3.2+
- `curl` or `wget` (for `init` command)

## Uninstall

```bash
rm /usr/local/bin/dotcontext
```
