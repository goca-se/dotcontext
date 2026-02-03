# Changelog

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
