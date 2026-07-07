# Changelog

## [Unreleased]

### Features

* **spec → plan → execute workflow** — feature development is now a three-command pipeline that replaces the single-shot PRP flow (ADR-020):
  * **`/spec-dc`** — writes a **behavior specification** (the WHAT) to `.context/specs/spec-<unix-ts>-<slug>.md`. Keeps dotcontext's **clarity assessment** and reference-material handling; describes observable behavior only, and **does not review ADRs**. Closes with a **dual reviewer loop** (`spec-dc/reviewer-pro` + `spec-dc/reviewer-fast`) scoped to well-formedness, testability, scope, grounding, and fidelity to the request — never product merit (that stays the user's call).
  * **`/plan-dc`** — turns a spec into an **implementation plan** (the HOW) in `.context/plans/plan-<unix-ts>-<slug>.md` with a **100% Traceability table**, and **owns the ADR review** for the whole flow (moved out of the old `generate-prp`). Preserves the PRP flow's **Validation Gate** (user approval on the approach before the detailed plan) and its **four-option ADR-conflict resolution** (Update / Find alternative / Keep / Let Claude decide) with version/History/Supersede mechanics. Closes with a **dual adversarial review loop** (`plan-dc/reviewer-pro` + `plan-dc/reviewer-fast`) until double-`APPROVED`.
  * **`AskUserQuestion` (ADR-005) stays mandatory and explicit** in all three commands — never degraded to free text; renders to each harness's native structured-question tool via `{{ASK}}` (ADR-018).
  * **`/execute-dc`** — implements the plan as **parallel waves** (disjoint files per wave), runs the project's tests after each wave, and finishes with a **dual review** of the `git diff` vs the plan (`execute-dc/reviewer-pro` + `execute-dc/reviewer-fast`). Branches from the repo's **detected base branch** (no hardcoded `develop`), keeps the **worktree isolation** option, and references knowledge reconciliation (ADR-019) as a deferred final step.
  * Adapted from the Spec-Driven Development skills (spec-author / plan-author / plan-executor), folded into dotcontext's conventions (portable across all six harnesses via `DOTCONTEXT_COMMANDS`; `## Workflows` in `AGENTS.md`).
* **`generate-prp` / `execute-prp` retired** — replaced by the trio. **Non-destructive on `update`**: existing projects keep their current PRP command files and `.context/prp/` untouched (they simply stop being managed), so nothing breaks — new projects get the trio.

## [0.17.1](https://github.com/goca-se/dotcontext/compare/v0.17.0...v0.17.1) (2026-07-01)

### Fixes

* **frontmatter** - complete `description` + `argument-hint` on all slash commands, and `name` + `description` on all skills and agent definitions (agent files were previously invalid subagent definitions)
* **update** - seed all four skills on `dotcontext update`; `batch-operations` and `git-platform` were missing, so existing projects never received them

## [0.17.0](https://github.com/goca-se/dotcontext/compare/v0.16.0...v0.17.0) (2026-06-03)

### Features

* **multi-agent commands & skill discovery (phase 2b)** — completes the multi-agent story for skills and workflows (ADR-018):
  * **skill frontmatter** — every `SKILL.md` now carries YAML `name` + `description`, so the model can **auto-discover** skills by description on every agent (not just via explicit `/name`). Applied to `bug-reproduction`, `batch-operations`, `git-platform`, `update-api-documentation`
  * **commands across harnesses (hybrid)** — the 12 workflow prompts now reach non-Claude agents: **opencode** gets `.opencode/command/*.md` and **Copilot** gets `.github/prompts/*.prompt.md` (native copies); **Gemini/Cursor/Codex** get a new **`## Workflows`** section in `AGENTS.md` that lists each workflow and tells the agent to use its native structured-question tool for clarification. Claude keeps `.claude/commands/`
  * **`--version --json`** now reports `commands: true`
  * **`/add-skill` updated** — it now generates the new skill format (YAML `name`/`description` frontmatter, description front-loaded for discovery) instead of the old `# Skill:`-only format, and notes the `.agents/skills` mirror for non-Claude agents
  * emission is per **selected** harness and create-only (no junk, no clobber)
* **new `update-api-documentation` skill** (#10, @anachronicsofa) — keeps external API/webhook contracts documented from a single OpenAPI source of truth (`docs/openapi.yml`), with generated Redoc HTML, `docs:validate`/`docs:build` tasks, and a CI step. Stack-agnostic (Rails/Node/Python examples). Merged after v0.16.0, so it ships in this release.
* **release notes from `CHANGELOG.md`** — `release.yml` now uses the matching `CHANGELOG.md` section as the GitHub release body (squash-merges made the old git-log notes one line); falls back to the git log when no section exists.

### Fixes

* **commands now read/write `AGENTS.md`, not the `CLAUDE.md` stub** — `setup-context` writes project instructions to `AGENTS.md`; `fix-bug`, `execute-prp`, `deep-context`, and `code-review` read `AGENTS.md`. Previously they targeted `CLAUDE.md`, which is now just an `@AGENTS.md` import stub (so they were getting near-empty content).
* **`doctor` no longer fails on valid non-Claude projects** — a missing Claude CLI is a warning, and the commands check recognizes `.opencode/command`, `.github/prompts`, and the `AGENTS.md` Workflows section.
* consistency sweep across docs and ADRs (README, root `CLAUDE.md`, `CONTEXT.md`, ADR-003/004/005/015/016): removed stale "Claude-only" framing, the removed `--force` flag, and dangling/`forthcoming` ADR references.

### Docs

* added **`CONTRIBUTING.md`** (skill-first, with the full deploy/release flow), GitHub **issue templates** + a **pull request template**.
* humanized `CONTRIBUTING.md` and the README multi-agent section.

### Notes

* Per-agent command files are emitted in markdown-compatible form (opencode/Copilot) — Gemini TOML / Cursor skill / Codex global-prompt transforms were intentionally **not** generated (format-divergent, not runtime-verifiable); those agents use the `AGENTS.md` Workflows section instead. The `code-review`/`deep-context` → skill-mode promotion (ADR-018 item 1) is recorded but deferred — they still ship as commands.

## [0.16.0](https://github.com/goca-se/dotcontext/compare/v0.15.0...v0.16.0) (2026-06-03)

### Features

* **multi-agent support** — dotcontext now targets six harnesses (Claude Code, OpenAI Codex, opencode, Gemini CLI, GitHub Copilot, Cursor incl. `cursor-agent`) instead of Claude only (ADR-016, ADR-017):
  * **extensible adapter registry** (`src/setup/agents.sh`) — each agent is one entry (`id`, name, detection, instructions file, emit mode). Adding an agent is a single case arm
  * **harness selection — only emit what you choose** — `init` confirms each detected agent interactively, or takes `--agents claude,codex` (non-interactive), or `--yes` (all detected). A Codex-only project gets **no `.claude/`** — no junk
  * **instructions** — canonical **`AGENTS.md`** read natively by Codex/opencode/Copilot/Cursor; **Claude** (`CLAUDE.md`) and **Gemini** (`GEMINI.md`) via thin `@AGENTS.md` import stubs. Single source, no duplication
  * **skills** — shared `SKILL.md` content emitted to `.agents/skills/` (Codex/opencode/Gemini/Copilot/Cursor) mirrored to `.claude/skills/` (Claude) via symlink (copy fallback)
  * **hooks** — a "task finished / needs attention" notification wired per selected harness in its native config (`.codex/hooks.json`, `.gemini/settings.json`, `.github/hooks/`, `.cursor/hooks.json`, opencode JS plugin); Claude also keeps the tool-failure guard
  * **`update` migrates legacy projects** — a content-bearing `CLAUDE.md` with no `AGENTS.md` is offered migration into the shared `AGENTS.md` (content- and behavior-preserving), plus a `GEMINI.md` stub when the Gemini CLI is present
  * **`--version --json`** reports `multiagent: true`, `skills: true`, `hooks: true` and the supported `agents` list; **`doctor`** is `AGENTS.md`-aware and reports detected agents

### Notes

* Slash **commands** remain Claude-native; per-agent command ports (ADR-018 — invocation-mode classification + a portable `{{ASK}}` rendered to each agent's native structured-question tool) are the next phase. Non-Claude hook configs are validated as well-formed but are best-effort (not runtime-tested per agent); the tool-failure guard stays Claude-only.

## [0.15.0](https://github.com/goca-se/dotcontext/compare/v0.14.2...v0.15.0) (2026-06-02)

### Features

* **update awareness in `doctor`** — `dotcontext doctor` now ends with a best-effort, day-cached check against the latest GitHub release and reports `update available: X → Y` or `up to date`. Silent when offline; never fails the health check. New shared helpers `fetch_latest_version()` / `version_gt()` in `src/core/utils.sh` (ADR-015)
* **capability handshake** — `dotcontext --version` gains `--features` (human-readable capability list) and `--json` (machine-readable handshake with `commands` + `capabilities`, no jq dependency) so an agent/harness can discover support before invoking. `multiagent: false` / `agents: ["claude"]` today — flips when multi-agent lands (ADR-015)
* **automated release pipeline** — `.github/workflows/release.yml` publishes a GitHub release on `v*` tag push, generating notes from `git log`; verifies the built binary is in sync with `src/` and that the tag matches `VERSION`. New `.github/workflows/ci.yml` runs `bash -n` + the build-in-sync check on PRs (ADR-014)
* **shell completion offered at `init`** — interactive `dotcontext init` now offers to wire tab-completion into `~/.zshrc`/`~/.bashrc`

### Changes

* **version single-source-of-truth** — `VERSION` now lives only in `src/header.sh`; the `/release` flow bumps it and runs `make build` instead of editing the built binary with `sed`, eliminating the source↔binary drift that affected v0.14.2 (ADR-014)
* removed the `--force` alias from `dotcontext update` (use `--yes`/`--dry-run`); removed the unused `slugify()` helper; dropped the low-value `skills/README.md` seed template. ADR-003 updated to v2.0 to document the seed/managed split. (`decisions/README.md` and the `bug-reproduction` skill are kept — both are load-bearing for `/add-decision`/`/setup-context` and `/fix-bug` respectively)

## [0.14.2](https://github.com/goca-se/dotcontext/compare/v0.14.1...v0.14.2) (2026-06-02)

### Features

* **PRP clarity, rigor & parallelism** — selectively absorbs spec-driven-build ideas into the existing PRP workflow:
  * **`/generate-prp`** — replaces the mandatory 10-question quota with a clarity-assessment policy (0..N questions, only when genuinely needed); adds a Validation Gate that dispatches a parallel Haiku subagent to verify referenced files exist, snippets are compilable, criteria are objectively verifiable, and change sets are mutually exclusive; adds Snippet Quality Rules (`file:line` refs, real type names, no placeholders)
  * **`feature.md` template** — Scope split into "What changes" / "What doesn't change"; strict path-level Affected files table; optional ASCII flow; mandatory end-to-end verification phase; new Parallelism Map for concurrent dispatch
  * **`/execute-prp`** — reads the Parallelism Map to dispatch independent phases concurrently via Task subagents
  * **ADR-005 → v2.0** — decision updated from "asks 10 custom clarifying questions" to "asks N (0..N) based on a clarity assessment"; spirit ("always ask before assuming") preserved
  * **propagation** — `feature.md` promoted from seed to managed in `src/commands/update.sh` so existing projects receive the new schema via `dotcontext update --templates`

## [0.14.1](https://github.com/goca-se/dotcontext/compare/v0.14.0...v0.14.1) (2026-04-23)

### Features

* **statusline rewrite** — richer StatusLine output with new segments and accurate context tracking:
  * **1M-context awareness** — detects Opus 4.7 `[1m]` extended mode and scales the context window to 1,000,000 tokens (falls back to 200k otherwise)
  * **context usage bar** — 8-segment colored bar (🟢 🟡 🟠 🔴 🚨) driven by the latest assistant `usage` from the transcript, with `AUTO-COMPACT!` / `LOW!` alerts surfaced from `system_message` entries
  * **session metrics** — cost (💰, colored by threshold and formatted in ¢ under $0.01), duration (⏱), and net lines (📝 ±N) pulled from the hook JSON
  * **relative directory** — shows the current dir relative to project root when nested
  * **richer git segment** — branch with change count, colored red when dirty / green when clean
  * **graceful jq fallback** — prints an install hint and exits cleanly when `jq` is missing instead of producing a broken line

### Docs

* **`/setup-context`** — StatusLine prompt updated to describe the new segments and notes the `jq` runtime dependency
* **README** — StatusLine description updated to match the new output

## [0.14.0](https://github.com/goca-se/dotcontext/compare/v0.13.3...v0.14.0) (2026-03-06)

### Features

* **project-local hooks** — notification and stop hooks now configured in `.claude/settings.json` (project) instead of `~/.claude/settings.json` (global)
* **tool failure guard** — new `PostToolUseFailure` hook that stops Claude after 4+ consecutive failures, triggers error sound + notification + AskUserQuestion
* **batch-operations skill** — 4-step workflow (scope, batch, verify, clean up) for large refactors
* **git-platform detection skill** — auto-detects GitHub/GitLab/Azure DevOps/Bitbucket from remote URL
* **multi-platform commands** — create-pr, pr-comment, code-review, fix-bug now detect git platform
* **improved fix-bug investigator** — stack trace analysis, binary search debugging, type tracing, intermittent bug handling
* **.claudeignore template** — shipped on init with sensible defaults for all project types
* **CLAUDE.md efficiency rules** — read before changing, follow existing patterns, code only, progressive loading, targeted tests
* **CLAUDE.md compact instructions** — what to preserve/remove during context compaction

### Changes

* doctor now checks project-local hooks and warns about legacy global hooks
* `notify.sh` and `tool-failure-guard.sh` installed to project `.claude/scripts/`

## [0.13.3](https://github.com/goca-se/dotcontext/compare/v0.13.2...v0.13.3) (2026-03-05)

### Changes

* **context** - update CONTEXT.md with modular src/ directory structure
* **decisions** - add ADR-012 (Agent File Extraction) and ADR-013 (Structured Exploration)
* **mcp** - add .mcp.json with context7 MCP server configuration

## [0.13.2](https://github.com/goca-se/dotcontext/compare/v0.13.1...v0.13.2) (2026-03-05)

### Fixes

* **zsh completion** — replaced `_dotcontext "$@"` with `compdef _dotcontext dotcontext` to prevent `_arguments` error when eval'd
* **shell auto-detection** — `dotcontext completion` without arguments now detects zsh vs bash automatically via `$ZSH_VERSION`

## [0.13.1](https://github.com/goca-se/dotcontext/compare/v0.13.0...v0.13.1) (2026-03-05)

### Docs

* **README** — added `completion` to CLI commands table, `/release` to Claude Code commands table, new "Shell Completion" section with bash/zsh setup instructions

## [0.13.0](https://github.com/goca-se/dotcontext/compare/v0.12.0...v0.13.0) (2026-03-05)

### Features

* **modular source architecture** — split monolithic script into 14 `src/` modules (`core/`, `commands/`, `setup/`) with `Makefile` build system; still ships as single executable
* **colored help screen** — grouped layout with BLUE BOLD headers, CYAN commands, YELLOW options, and adaptive column widths based on terminal width
* **icon system** — 16 `ICON_*` constants replacing hardcoded symbols across doctor, init, and update output; structured output blocks with `print_block_header`/`print_block_footer`
* **shell tab completion** — `dotcontext completion bash|zsh` generates working completions with per-subcommand option awareness
* **TTY-safe colors** — `[[ -t 1 ]]` detection strips escape codes when output is piped

### Changes

* **ADR-001 v2.0** — updated to reflect modular source with build-time bundling
* **CLAUDE.md** — architecture section updated, `completion` command documented

## [0.12.0](https://github.com/goca-se/dotcontext/compare/v0.11.0...v0.12.0) (2026-03-05)

### Features

* **`/deep-context` restructured to 4-step exploration** — Replaced the 5-agent model (scope-guardian, primary-explorer, cross-repo-explorer, cross-repo-validator, reviewer-output) with a structured 4-step progression:
  * Step 1: Overview Agent — architecture summary, key files, entry points
  * Step 2: Subsystem Agent — module map, interdependencies, boundaries
  * Step 3: Drill Agent — targeted deep-dive into relevant areas
  * Step 4: Data Flow Agent — trace information movement through the system
  * Steps 1+2 run in parallel, Steps 3+4 run sequentially (each builds on prior outputs)
  * Cross-repo analysis integrated into Steps 1+2 via appended instructions
* **Declarative managed directory cleanup** — New `cleanup_managed_dir()` function removes stale files from managed-only directories (agents, scripts) using a desired-state allow-list, eliminating the need for explicit migration code on future renames or removals
  * Guards against empty expected list (no-op) and preserves symlinks
  * Excludes `.claude/commands/` since users create custom commands there via `/add-command`
* **ADR-013: Structured Exploration Pattern** — Documents the 4-step exploration architecture and rationale

### Fixes

* **Stale agent references** — `dotcontext init` and `update` referenced deleted deep-context agent files (would 404 on download); updated to new step-based agents
* **Agent count** — Init output corrected from 13 to 12 agents

### Changes

* **README updated** — Skills directory corrected (`.context/skills/` → `.claude/skills/`), MCP server configuration documented, deep-context architecture updated from 5-agent to 4-step model

## [0.11.0](https://github.com/goca-se/dotcontext/compare/v0.10.2...v0.11.0) (2026-03-04)

### Features

* **`/commit` command** — Smart commit workflow with style-aware message generation:
  * detects project commit style from git log (conventional commits vs freeform)
  * interactive staging via AskUserQuestion (multiSelect, directory grouping)
  * diff analysis and AI-generated commit messages
  * user confirmation before committing, `--amend` support
* **`dotcontext doctor`** — New CLI subcommand for project health validation:
  * 11 checks: Claude CLI, .context/ structure, CLAUDE.md, CONTEXT.md, decisions, commands, agents, skills, MCP config, notification hooks, git status
  * colored pass/fail/warn output with summary line
* **StatusLine** — At-a-glance project context in Claude Code:
  * script showing model, context %, git branch+changes, .context health
  * configured via new task 8 in `/setup-context`
  * downloaded during `dotcontext init`, managed on update
* **Agent extraction** — 13 inline agent prompts extracted to reusable `.claude/agents/` files:
  * `/code-review`: compliance-checker, bug-detector, security-analyst (3 agents)
  * `/deep-context`: scope-guardian, primary-explorer, cross-repo-explorer, cross-repo-validator, reviewer-output (5 agents)
  * `/fix-bug`: investigator, fix-conservative, fix-minimal, fix-refactor, reviewer (5 agents)
  * commands now reference agents via `Read .claude/agents/...` — behavior unchanged
  * agents included in managed templates for init and update
* **ADR-012: Agent File Extraction Pattern** — Documents the file-based agent architecture
* **Update safety** — `exec` re-exec after CLI update ensures templates use the new managed list in a single `dotcontext update` run

### Changes

* **Skills directory migration** — Moved `.context/skills/` to `.claude/skills/` with updated references across commands and templates

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
