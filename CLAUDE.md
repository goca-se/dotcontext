# dotcontext

> AI context toolkit for coding agents (Claude Code, Codex, opencode, Gemini, Copilot, Cursor) — commands, decisions, skills, and feature planning for your codebase.

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
# Initialize context structure in a project (harness-selective; auto-runs /setup-context when Claude is selected)
dotcontext init [--name "Project Name"] [--agents claude,codex,...] [--yes] [--no-setup]

# Update CLI + templates
dotcontext update                     # Update CLI + templates (if in project)
dotcontext update --cli               # Only update CLI
dotcontext update --templates         # Only update templates

# Validate project setup
dotcontext doctor

# Shell tab completion
dotcontext completion [bash|zsh]

# Help / version (--features and --json expose the capability handshake)
dotcontext --help
dotcontext --version [--features|--json]
```

### Claude Code (interactive with questions)

```bash
/setup-context             # Analyze codebase and populate context
/spec-dc [feature]         # Write a behavior spec — the WHAT (step 1)
/plan-dc [spec-path]       # Turn a spec into a plan (ADR review) — the HOW (step 2)
/execute-dc [plan-path]    # Implement a plan in parallel waves — the DO (step 3)
/code-review               # Review code changes
/commit [--amend]          # Smart commit with style-aware messages
/deep-context [query]      # Structured 4-step codebase exploration
/fix-bug [description]     # Test-driven bug fixing with parallel agents
/create-pr                 # Create PR with auto-generated description
/pr-comment                # Add comment to existing PR
/release [patch|minor|major] # Create release with version bump
/add-decision              # Add ADR interactively
/add-skill                 # Add skill guide interactively
/add-command               # Create custom command interactively
```

## Critical Rules

1. **Always ask before assuming** - When there is ambiguity, multiple valid approaches, or decisions to be made, use the AskUserQuestion tool to clarify before proceeding. Never assume user intent.
2. **POSIX compatibility** - Use Bash 3.2+ compatible syntax (macOS ships with 3.2). Avoid bashisms that require newer versions.
3. **Safe defaults** - Never overwrite existing user content: seed files are create-only, and managed files show a diff and prompt (`--yes` to skip) before updating. Always prompt before destructive operations.
4. **Template downloads** - Templates are fetched from GitHub `main` branch. Validate downloads before using.
5. **Cross-platform support** - Test on macOS, Linux, and Windows/WSL. Platform-specific code must have proper detection and fallbacks.

## Architecture

### Single Executable Pattern

The CLI is distributed as a single `dotcontext` bash script. Source code lives in `src/` modules (`core/`, `commands/`, `setup/`) and is bundled into the single executable via `make build`. All commands are implemented as functions, routed via a case statement. This keeps development modular while simplifying distribution.

### Template-Based Init

Templates live in `templates/` directory on GitHub and are downloaded during `dotcontext init`. `init` is **harness-selective** — only the chosen agents' files are emitted:
- `templates/AGENTS.md` → project `AGENTS.md` (the **canonical** instructions, always emitted)
- `templates/CLAUDE.md` / `templates/GEMINI.md` → thin `@AGENTS.md` import stubs (emitted only for Claude / Gemini)
- `templates/.context/` → project `.context/` directory
- `.claude/` (commands, agents, statusline, hooks) is emitted **only when Claude is selected**

### Multi-Agent Integration

Six harnesses are supported (Claude Code, Codex, opencode, Gemini CLI, Copilot, Cursor) via an adapter registry (`src/setup/agents.sh`). Workflows reach each harness in its native form: Claude `.claude/commands/`, opencode `.opencode/command/`, Copilot `.github/prompts/`, and a `## Workflows` section in `AGENTS.md` for Gemini/Cursor/Codex. Skills (`SKILL.md` with `name`/`description` frontmatter) go to `.claude/skills/` and/or `.agents/skills/`. See ADR-016/017/018.

---

## Additional Context

- Domain and architecture → `.context/CONTEXT.md`
- Architectural decisions → `.context/decisions/`
- Task-specific skills → `.claude/skills/`
- Bug reproduction guide → `.claude/skills/bug-reproduction/SKILL.md`
