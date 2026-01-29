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

This creates the context structure and downloads templates.

**Options:**
```bash
dotcontext init --name "My Project"  # Set project name
dotcontext init --yes                # Skip prompts, use defaults
```

### Add context files

```bash
dotcontext add decision    # Architectural Decision Record
dotcontext add skill       # Step-by-step guide
dotcontext add prp         # Feature planning doc
dotcontext add command     # Claude Code slash command
```

### Update CLI

```bash
dotcontext update              # Update CLI to latest version
```

### Update templates

When new templates or commands are added to dotcontext, update your project:

```bash
dotcontext update --templates          # Add new files only
dotcontext update --templates --force  # Overwrite existing files
```

This is **safe by default**:
- Only adds NEW files
- Never overwrites your existing content
- Use `--force` only if you want to reset templates

### Run the setup command

After initialization, open Claude Code:

```bash
claude
> /setup-context
```

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
| `dotcontext update` | Update CLI to latest version |
| `dotcontext update --templates` | Add new templates to project |
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

## Requirements

- Bash 3.2+
- `curl` or `wget`

## Uninstall

```bash
rm /usr/local/bin/dotcontext
```
