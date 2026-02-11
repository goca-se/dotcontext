# Changelog

## [0.10.0](https://github.com/goca-se/dotcontext/compare/v0.9.0...v0.10.0) (2026-02-10)

### Features

* **`/fix-bug` command** — Test-driven bug fixing with parallel subagents:
  * zero questions — goes straight from bug description to investigation
  * investigator agent identifies root cause and writes a failing reproduction test
  * N parallel fix agents (default 3) with diverse strategies: conservative, minimal, refactor
  * all agents run to completion — selects best fix, not just first fix
  * reviewer agent compares, combines, and validates fixes
  * `--issue N` flag to include GitHub issue context via `gh`
  * `--pr N` flag to include PR context via `gh`
  * `--agents N` flag to configure number of parallel fix agents
  * bug report saved to `.context/bugs/YYYYMMDD-[slug].md`
  * AskUserQuestion used only for fix selection (ADR-011 exception to ADR-005)
* **`bug-reproduction` skill template** — Project-specific bug reproduction guide:
  * created during `dotcontext init`
  * populated by `/setup-context` with test framework, commands, and examples
  * includes UI bugs section with markdown test plans
* **`.context/bugs/` directory** — New directory in scaffold for bug fix reports
* **ADR-011: Test-Driven Bug Fixing Pattern** — Documents the zero-questions exception and parallel fix architecture
* **`/setup-context` step 6** — New step to populate bug-reproduction skill with project-specific test framework
* **`/generate-prp` next steps prompt** — After PRP generation, offers "Execute now", "Review first", or "Edit PRP" via AskUserQuestion instead of static text; advises `/clear` before executing to avoid degraded context
* **`.context/prp/` removed from version control** — PRP templates and generated PRPs are session-specific; removed `.keep` files and `feature.md` template from tracked files (they are downloaded from GitHub on init)
* **safe re-init** — `dotcontext init` on an existing project no longer overwrites user content:
  * seed files (CLAUDE.md, CONTEXT.md, READMEs, skills) are skipped if they already exist
  * managed files (commands) are always updated to latest
  * directories are created if missing (mkdir -p, always safe)
  * shows "skipped (exists)" for each preserved file
  * `{{projectName}}` substitution only runs if placeholder is still present
* **unified `dotcontext update`** — single command now updates CLI + templates:
  * `dotcontext update` — updates CLI from release tag, then checks templates (if in project)
  * `--cli` flag for CLI-only update, `--templates` flag for templates-only
  * CLI now downloads from release tag (not main branch) — no unreleased code
  * removed `migrate_hooks()` dead code (v0.6→v0.7 migration, no longer needed)
* **`update --templates` two-category safety** — Template manifest split into "managed" and "seed":
  * managed: `.claude/commands/*.md` — dotcontext code, always offered for update
  * seed: `decisions/README.md`, `skills/README.md`, `skills/bug-reproduction/SKILL.md`, `prp/templates/feature.md` — created once, never overwritten
  * seed files show as `• (user-managed — skipped)` in update output
  * protects user content from accidental overwrite, even with `--yes`
* **install.sh rewrite** — Complete overhaul of the installation experience:
  * downloads from latest release tag (not `main` branch) — no unreleased code
  * braille dot art logo with side-by-side layout: version, files, and key commands next to the logo
  * compact single-line quick start guide
  * `curl -f` flag for HTTP error detection (consistent with CLI)
* **braille spinner animation** — Animated braille dot spinner (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`) during network operations:
  * `dotcontext init` — while downloading templates
  * `dotcontext update` — while checking for updates and downloading
  * `install.sh` — while downloading CLI
* **compact init output** — `dotcontext init` now shows a concise 3-line summary instead of full file tree and command list

## [0.9.0](https://github.com/goca-se/dotcontext/compare/v0.8.1...v0.9.0) (2026-02-10)

### Features

* **`/deep-context` command** — Multi-agent business rule discovery across repositories:
  * orchestrates 5 specialized agents (Compliance, Explorer, Cross-Repo, Validator, Reviewer)
  * phased execution: Agents 1-3 parallel, Agent 4 sequential, Agent 5 final review
  * auto-detects related repos from `.context/CONTEXT.md` external integrations
  * `--repo` flag for manual related repo specification (local path or git URL)
  * `--cache` flag to reference previous discoveries in `.context/discoveries/`
  * confidence-based filtering (findings below 50% auto-removed)
  * every finding backed by `file:line` references — no fabricated information
  * output saved to `.context/discoveries/YYYYMMDD-[slug].md`
  * executive summary + detailed findings in single structured document
* **`.context/discoveries/` directory** — New directory in scaffold for discovery outputs
* **ADR-009: Multi-Agent Orchestration Pattern** — Documents the agent communication pattern using Task tool
* **ADR-010: Discovery Output Format** — Standardizes the discovery document format
* **`/setup-context` ensures .gitignore** — New step 6 adds `.context/prp/` and `.context/discoveries/` to `.gitignore` automatically

### Fixes

* **download validation** — `curl` now uses `-f` flag to fail on HTTP 404/5xx instead of saving error pages as file content
* **`.context/prp/` removed from version control** — Generated PRPs are session-specific and should not be committed

## [0.8.1](https://github.com/goca-se/dotcontext/compare/v0.8.0...v0.8.1) (2026-02-03)

### Features

* **PRP reference materials** - PRPs now preserve references to visual materials (images, PDFs, layouts):
  * new "Reference Materials" section in PRP template for documenting visual references
  * `/generate-prp` instructions to extract and document file paths for visual references
  * `/execute-prp` checks Reference Materials section before starting implementation
  * prevents loss of visual context after `/clear`

### Fixes

* **Docker detection** - setup-context and CLAUDE.md template now detect Docker usage:
  * checks for `docker-compose.yml`, `Dockerfile` in project
  * instructs agents to use `docker compose exec` prefix for commands when Docker is present

## [0.8.0](https://github.com/goca-se/dotcontext/compare/v0.7.0...v0.8.0) (2026-02-03)

### Features

* add "If You Get Stuck" section to all commands - instructs agent to stop and ask user after 3 failed attempts instead of looping indefinitely
* **`dotcontext update --templates` now shows preview before updating** - Terraform-style UX:
  * compares local vs remote templates and shows diff summary
  * categorizes files as: new (+), modified (~), unchanged (=)
  * prompts before overwriting: `y` = update all, `N` = only add new (default), `d` = show diffs first
  * `--dry-run` flag to preview changes without applying
  * `--yes` flag to update without prompting (useful for CI)
  * only updates "code" files (commands, PRP template), never touches user content (CONTEXT.md, CLAUDE.md, user ADRs/skills)
* **`/create-pr` command** - Create well-structured PRs with automatic architecture diagram detection:
  * analyzes changes and generates appropriate PR title/description
  * detects architectural changes and suggests Mermaid diagrams (sequence, flowchart, etc.)
  * auto-pushes branch with confirmation if not on remote
  * respects existing PR templates if present
* **`/pr-comment` command** - Add comments to existing PRs:
  * supports general comments, review comments, diagram explanations, status updates
  * auto-generates Mermaid diagrams when discussing architecture
  * integrates with `/code-review` for follow-up comments
* **`/code-review` multi-agent architecture** - complete rewrite inspired by [Claude Code's official plugin](https://github.com/anthropics/claude-code/tree/main/plugins/code-review):
  * launches 4 parallel review agents (2x CLAUDE.md compliance, 1x bug detection, 1x security & history)
  * confidence-based scoring (0-100) with threshold ≥80 to filter false positives
  * automatic context gathering (finds all CLAUDE.md files, fetches PR diff)
  * git blame/history analysis for pattern violations
  * pre-flight checks (skips closed, draft, already-reviewed PRs)
  * `--comment` flag to post review directly as PR comment via `gh`
  * explicit list of false positives to ignore (pre-existing issues, linter-catchable, etc.)

### Changes

* rename `/dotcontext-add-*` commands to `/add-*` for brevity:
  * `/dotcontext-add-decision` → `/add-decision`
  * `/dotcontext-add-skill` → `/add-skill`
  * `/dotcontext-add-command` → `/add-command`

## [0.7.0](https://github.com/goca-se/dotcontext/compare/v0.6.0...v0.7.0) (2026-02-02)

### ⚠ BREAKING CHANGES

* **CLI commands removed:** `dotcontext add decision|skill|prp|command` no longer exist
  * Use Claude Code commands instead: `/dotcontext-add-decision`, `/dotcontext-add-skill`, `/dotcontext-add-command`, `/generate-prp`
* **init behavior changed:** Now automatically opens Claude Code with `/setup-context`
  * Use `--no-setup` flag to skip this behavior

### Features

* `dotcontext init` now auto-runs `/setup-context` in Claude Code
* add `--no-setup` flag to skip automatic setup
* add Decision Compliance Check to `/execute-prp` - detects conflicts with existing ADRs and asks user how to proceed
* add Decision Awareness to `/generate-prp` - identifies impacted ADRs and new decisions required
* add "Decisions" section to PRP template (existing + new decisions)
* add ADR versioning with `Version` field and `History` section
* add Progress Tracking instructions to PRPs - mark tasks, phases, and success criteria as `[x]` when completed
* add automatic hooks migration on `dotcontext update`

### Removals

* remove `dotcontext add` commands (use Claude Code slash commands instead)
* remove `.context/examples/` directory from scaffold (examples belong in skills)

### Migrations

* **Hooks format:** If you have hooks in `~/.claude/settings.json` from a previous version, run `dotcontext update` to automatically migrate to the new format

## [0.6.0](https://github.com/goca-se/dotcontext/compare/v0.5.0...v0.6.0) (2026-02-02)

### Features

* add native OS notifications (macOS, Linux, Windows/WSL)
* add `/dotcontext-add-decision` slash command for interactive ADR creation
* add `/dotcontext-add-skill` slash command for interactive skill creation
* add `/dotcontext-add-command` slash command for custom command creation
* auto-configure notification hooks on `dotcontext init`

### Changes

* remove release-please automation (manual versioning)

## [0.5.0](https://github.com/goca-se/dotcontext/compare/v0.4.0...v0.5.0) (2026-02-02)

### Features

* add worktree isolation to execute-prp for parallel development
* enforce AskUserQuestion tool usage across all commands

### Documentation

* update README with accurate command descriptions

## [0.4.0](https://github.com/goca-se/dotcontext/releases/tag/v0.4.0) (2026-01-31)

### Features

* add MIT license
* add generate-prp and execute-prp commands
* add update command and decision compliance

## [0.3.0](https://github.com/goca-se/dotcontext/releases/tag/v0.3.0)

* Initial release
