# dotcontext

> AI context toolkit for Claude Code — commands, decisions, skills, and feature planning for your codebase.

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
# Open marketplace TUI (Browse / Installed / Status)
dotcontext

# Initialize Layer 1 in a project (auto-runs /setup-context)
dotcontext init [--name "Project Name"] [--yes] [--no-setup]

# Update CLI + Layer 1 templates + run auto-migration once
dotcontext update                     # full update flow
dotcontext update --cli               # only update CLI
dotcontext update --templates         # only update Layer 1 templates

# Help / version
dotcontext --help
dotcontext --version
```

> Removed in v0.15: `dotcontext doctor` (use Status tab in TUI), `dotcontext completion` (regenerate locally).

### Claude Code

**Layer 1 (always present after `init`)** — the absolute minimum:

```bash
/setup-context              # Guided codebase analysis interview (the only Layer 1 command)
```

**Layer 2 (install via marketplace TUI — `dotcontext`):**

The 16-item starter pack covers the common case (press `p` then `i` in the TUI):

```bash
/add-decision               # Add ADR (schema 2.0)
/add-skill                  # Add skill guide
/add-command                # Create custom command
/commit [--amend]           # Smart commit
/deep-context [query]       # Structured 4-step exploration
/generate-prp [feature]     # Plan a feature with a PRP
/execute-prp [name]         # Execute a planned PRP
/code-review                # Multi-agent review (3 agents)
/fix-bug [description]      # TDD bug fix (5 agents + skill)
/create-pr                  # Open PR / MR
/pr-comment                 # Comment on PR / MR
# + Atlassian, Grafana, Context7 MCPs
# + gh, glab CLIs
```

## Critical Rules

1. **Always ask before assuming** - When there is ambiguity, multiple valid approaches, or decisions to be made, use the AskUserQuestion tool to clarify before proceeding. Never assume user intent.
2. **POSIX compatibility** - Use Bash 3.2+ compatible syntax (macOS ships with 3.2). Avoid bashisms that require newer versions.
3. **Safe defaults** - Never overwrite existing files without `--force` flag. Always prompt before destructive operations.
4. **Template downloads** - Templates are fetched from GitHub `main` branch. Validate downloads before using.
5. **Cross-platform support** - Test on macOS, Linux, and Windows/WSL. Platform-specific code must have proper detection and fallbacks.

## Architecture

### Single Executable Pattern

The CLI is distributed as a single `dotcontext` bash script. Source code lives in `src/` modules (`core/`, `lib/ui/`, `lib/marketplace/`, `lib/install/`, `commands/`, `setup/`) and is bundled into the single executable via `make build`. All commands are implemented as functions, routed via a case statement.

### Two-Layer Distribution (ADR-015 v3.0)

- **Layer 1** is installed by `dotcontext init` — only the absolute bootstrap: `.context/` skeleton, `CLAUDE.md`, `.claudeignore`, and `/setup-context`. Nothing else.
- **Layer 2** is installed on-demand via the marketplace TUI — every other command (including `/commit`, `/deep-context`, `/add-*`, etc.), all agents, all skills, MCPs, external CLIs, hooks, scripts. The strict rule: anything that creates, populates, or consumes `.context/` beyond the initial bootstrap is Layer 2.

### Marketplace TUI (ADR-014)

Bash-native TUI in `src/lib/ui/` with three tabs: Browse · Installed · Status. The catalog and Layer 2 templates live in a separate repo — [goca-se/dotcontext-marketplace](https://github.com/goca-se/dotcontext-marketplace) — fetched by the CLI at runtime (cached at `~/.dotcontext/cache/manifest.json`). Per-scope lockfiles (`.context/.dotcontext-state.json` local; `~/.dotcontext/state.json` global) record what's installed. See ADRs 014, 015, 016, 017, 020.

### Template-Based Init

Layer 1 templates live in `templates/` (this repo) and are downloaded during `dotcontext init`. Layer 2 templates live in `templates/` in the marketplace repo and are fetched per-item by the bundle resolver.

### Claude Code Integration

Slash commands in `.claude/commands/` provide interactive workflows that integrate with Claude Code's tool system (AskUserQuestion, file operations, etc.).

---

## Additional Context

- Domain and architecture → `.context/CONTEXT.md`
- Architectural decisions → `.context/decisions/`
- Marketplace catalog → [goca-se/dotcontext-marketplace](https://github.com/goca-se/dotcontext-marketplace)
- Migration guide → `docs/MIGRATION.md`
