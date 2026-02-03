# dotcontext

> CLI tool that scaffolds and manages AI context structures for codebases, helping AI assistants understand projects better.

## Decision Compliance

**IMPORTANT:** Before implementing any change, check `.context/decisions/` for related ADRs.

If a requested change conflicts with an existing decision:
1. **Stop and inform the user** which ADR(s) would be affected
2. **Ask explicitly** if they want to:
   - Proceed and update the decision
   - Modify the approach to comply with existing decision
   - Cancel the change
3. **If updating a decision**, create a new version:
   - Change status to `Superseded by ADR-XXX`
   - Create new ADR with updated decision
   - Reference the previous ADR

## Stack

- Bash 3.2+ (POSIX-compatible shell scripting)
- Single executable distribution (no framework)
- No database (file-based templates)
- Dependencies: curl/wget, sed, grep, jq (optional)

## Commands

### CLI

```bash
# Initialize context structure in a project (auto-runs /setup-context)
dotcontext init [--name "Project Name"] [--yes] [--no-setup]

# Update CLI or templates
dotcontext update                     # Update CLI to latest
dotcontext update --templates         # Add new templates (safe)
dotcontext update --templates --force # Overwrite existing templates

# Help
dotcontext --help
dotcontext --version
```

### Claude Code (interactive with questions)

```bash
/setup-context             # Analyze codebase and populate context
/generate-prp [feature]    # Plan a new feature
/execute-prp [name]        # Implement a planned feature
/code-review               # Review code changes
/add-decision              # Add ADR interactively
/add-skill                 # Add skill guide interactively
/add-command               # Create custom command interactively
```

## Critical Rules

1. **Always ask before assuming** - When there is ambiguity, multiple valid approaches, or decisions to be made, use the AskUserQuestion tool to clarify before proceeding. Never assume user intent.
2. **POSIX compatibility** - Use Bash 3.2+ compatible syntax (macOS ships with 3.2). Avoid bashisms that require newer versions.
3. **Safe defaults** - Never overwrite existing files without `--force` flag. Always prompt before destructive operations.
4. **Template downloads** - Templates are fetched from GitHub `main` branch. Validate downloads before using.
5. **Cross-platform support** - Test on macOS, Linux, and Windows/WSL. Platform-specific code must have proper detection and fallbacks.

## Architecture

### Single Executable Pattern

The entire CLI is a single `dotcontext` bash script (~700 lines). All commands are implemented as functions within this script, routed via a case statement. This simplifies distribution and installation.

### Template-Based Scaffolding

Templates live in `templates/` directory on GitHub and are downloaded during `dotcontext init`. The structure mirrors what gets created in user projects:
- `templates/CLAUDE.md` → project root `CLAUDE.md`
- `templates/.context/` → project `.context/` directory

### Claude Code Integration

Slash commands in `.claude/commands/` provide interactive workflows that integrate with Claude Code's tool system (AskUserQuestion, file operations, etc.).

---

## Additional Context

- Domain and architecture → `.context/CONTEXT.md`
- Architectural decisions → `.context/decisions/`
- Task-specific skills → `.context/skills/`
