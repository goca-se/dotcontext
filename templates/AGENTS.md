# {{projectName}}

> [Project description - one line]

<!--
This is the canonical project-instructions file, read by AGENTS.md-compatible
agents (Codex, opencode, Copilot, Cursor, …). Claude Code and Gemini CLI read it
through thin import stubs (CLAUDE.md / GEMINI.md → @AGENTS.md). Edit this file.
-->

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

- [Language and version]
- [Framework]
- [Database]
- [Other major dependencies]

## Commands

**Important:** Check if this project uses Docker (docker-compose.yml, Dockerfile). If so, run commands via Docker (e.g., `docker compose exec app npm test` instead of `npm test`).

```bash
# Development
# [dev command]

# Testing
# [test command]

# Linting
# [lint command]

# Build/Deploy
# [build command]
```

## Critical Rules

1. **Always ask before assuming** - When there is ambiguity, multiple valid approaches, or decisions to be made, ask the user to clarify before proceeding (use your interactive question mechanism if you have one). Never assume user intent.
2. **[Rule 1]** - [Why it matters]
3. **[Rule 2]** - [Why it matters]
4. **[Rule 3]** - [Why it matters]

## Architecture

### [Section 1]

[Brief description of key architectural pattern]

### [Section 2]

[Brief description of another key pattern]

## Efficiency Rules

- **Read before changing** — Always read a file before editing it. Never modify code based on assumptions about its content.
- **Follow existing patterns** — Before implementing something new, look at how similar things are done in the codebase. Match the existing style, conventions, and patterns.
- **Scope reads to the task** — Only read files directly relevant to the change. Do not explore broadly before acting on focused tasks.
- **Load context progressively** — Start with the minimum files needed. Only expand to related files when the current context is insufficient to complete the task.
- **Code only** — When implementing changes, output code. Skip explanations, preamble, and commentary unless the user asks for them.
- **Skip summaries** — After making changes, do not summarize what you did unless asked. Show `git diff` instead.
- **Run targeted tests** — After a change, run only tests related to the modified files. Only run the full suite when asked or before committing.
- **Never read generated files** — Do not read lock files, build output, vendored dependencies, or source maps. These are listed in `.claudeignore`.

## Compact Instructions

When compacting, preserve:
- Test results and error output
- File paths and code changes made
- Key decisions and their rationale

Remove:
- Exploratory file reads that did not lead to changes
- Verbose command output that has been summarized
- Discussion of rejected approaches

---

## Additional Context

- Domain and architecture → `.context/CONTEXT.md`
- Architectural decisions → `.context/decisions/`
- Task-specific skills → `.claude/skills/`
- Bug reproduction guide → `.claude/skills/bug-reproduction/SKILL.md`
- Batch operations guide → `.claude/skills/batch-operations/SKILL.md`
- Git platform detection → `.claude/skills/git-platform/SKILL.md`
- API documentation (OpenAPI SSOT) → `.claude/skills/update-api-documentation/SKILL.md`
