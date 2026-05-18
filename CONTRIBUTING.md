# Contributing to dotcontext

Thanks for considering a contribution. dotcontext is opinionated but contribution-friendly: we have hard guardrails (tests, ADR compliance, bash 3.2 portability) and a lot of flexibility everywhere else. This guide explains both.

## TL;DR

- **Found a bug or want a small fix?** Open an issue or skip straight to a PR.
- **Want to add an item to the marketplace?** That's the highest-leverage contribution — see [Add a marketplace item](#add-a-marketplace-item).
- **Want to change harness internals (`src/`)?** Read [Harness changes](#change-harness-internals) first — it has stricter rules.
- **Want to improve docs or templates?** Just open a PR. No ADR needed.

If anything below is unclear, open an issue and we'll improve the guide.

## Quick start

```bash
git clone https://github.com/goca-se/dotcontext.git
cd dotcontext
make build              # bundles src/ into the single ./dotcontext binary
make check              # bash -n on src/lib/

# Optional: clone the marketplace adjacent for end-to-end testing
git clone https://github.com/goca-se/dotcontext-marketplace.git ../dotcontext-marketplace

# Try the TUI in an isolated sandbox (auto-detects adjacent marketplace clone):
bash tests/sandbox.sh
```

The build produces `./dotcontext` (~94 KB). `tests/sandbox.sh` sets `DOTCONTEXT_REPO_ROOT` (this repo) and, when an adjacent `../dotcontext-marketplace` exists, `DOTCONTEXT_MARKETPLACE_ROOT` (the marketplace clone) so install handlers read from local checkouts instead of GitHub.

## Where to start

dotcontext has four contribution surfaces. Pick the one that fits.

### Add a marketplace item

**Wrong repo.** The marketplace catalog (manifest + Layer 2 templates) lives in [**goca-se/dotcontext-marketplace**](https://github.com/goca-se/dotcontext-marketplace). PRs adding commands, skills, MCPs, CLIs, hooks, or scripts go there.

Why the split: keeps the harness focused on the CLI / TUI / install handlers, lets the catalog grow without bloating this repo, and lowers the bar for community catalog additions (no need to read bash 3.2 constraints to suggest a new MCP). See [ADR-020](.context/decisions/020-marketplace-source-topology.md).

If your change affects the manifest **schema** (adding a new item type, new required fields), that's a CLI change too — it touches `src/lib/marketplace/manifest.sh` and item handlers in `src/lib/install/`. Open a PR here in tandem with the marketplace PR.

### Change harness internals

Stricter rules apply because this is the code that runs on every user's machine.

- **Bash 3.2+ only.** macOS ships bash 3.2.57 (Apple frozen since 2007 over GPLv3). No associative arrays, no `mapfile`, no fractional `read -t`, no `${var,,}` lowercase. See `src/lib/ui/menu_paginated.sh` for an example of writing around 3.2 quirks (escape-sequence parsing without fractional timeouts).
- **No new runtime dependencies.** We rely on `bash`, `curl`/`wget`, `sed`, `grep`. `jq` is required for the marketplace TUI (parsing the manifest); validate-manifest works without it. Adding anything else needs an ADR.
- **`make build` produces a single bundled `dotcontext` script.** Put new code under `src/<module>/<file>.sh` and add it to `SOURCES` in the `Makefile` in dependency order (lib/ui before lib/marketplace before lib/install before commands).
- **Run tests:** `make check`, `bash tests/marketplace/smoke.sh`, `bash tests/marketplace/migrate_smoke.sh`.
- **TUI changes:** test in iTerm2, Terminal.app, or Ghostty. Warp doesn't support full-screen TUIs (it's block-based) — your changes can't be validated there.

### Update an ADR or propose a new one

We use [Architectural Decision Records](.context/decisions/) for anything a reviewer would find surprising six months later — choice of a particular approach, trade-off accepted, abstraction added.

- **New ADRs use schema 2.0.** Sections: Context, Decision, Alternatives Considered, **Trade-offs Accepted**, **Validation Criteria**, Consequences, Related ADRs, History. See [`.context/decisions/README.md`](.context/decisions/README.md) for the full template.
- **Existing v1 ADRs stay v1.** We don't migrate — coexistence is intentional ([ADR-019](.context/decisions/019-adr-template-v2-coexistence.md)).
- **`/add-decision` (in Claude Code) emits v2.** It detects the directory's dominant schema and warns once if you're introducing v2 into a v1-only project.
- **When does a change need an ADR?** When you're picking among reasonable alternatives and the choice has consequences a future reader couldn't reverse-engineer from code alone. Bug fixes, refactors, and "obvious" improvements don't need one. If your PR's "Why" section starts with "we considered X but chose Y because…", that's the ADR signal.
- **When updating an existing ADR:** bump `**Version:**`, add a `History` row, link the PRP/issue that drove the change. If the original decision is fully replaced, mark `**Status:** Superseded by ADR-NNN` and write a new ADR.

### Improve docs, templates, or prose

The lowest-friction path. Anything in `templates/` ships to user projects; anything in `docs/` or `README.md` is for contributors and consumers. Just open a PR — no ADR required unless you're changing established conventions.

The exception: editing `templates/.claude/commands/*.md` *is* changing harness behavior (these are slash commands users run). Treat those as small harness changes — test the resulting behavior before opening the PR.

## Project standards

| Standard | What it means |
|----------|---------------|
| **Bash 3.2+ compatibility** | macOS still ships 3.2.57. Test on macOS or document a compatibility constraint. |
| **POSIX-style scripts** | Use `[ ]` over `[[ ]]` when possible; quote variables; use `&&`/`\|\|` carefully under `set -e`. |
| **ADR compliance** | Before changing behavior covered by an ADR, read the ADR. If your change conflicts, update the ADR (or write a new one) **in the same PR**. |
| **Single-binary distribution** | Anything that breaks `curl \| bash` install needs an ADR ([ADR-001](.context/decisions/001-single-bash-executable.md)). |
| **Decision compliance check** | The CLAUDE.md template instructs Claude Code to read `.context/decisions/` before implementing. PRs that ignore an ADR will be flagged. |
| **`make check` passes** | Manifest validates, all `src/lib/*.sh` parses cleanly. CI will run this. |
| **Smoke tests pass** | `bash tests/marketplace/smoke.sh` and `tests/marketplace/migrate_smoke.sh` for changes affecting marketplace install/migration. |

## Workflow

1. **Fork** the repo on GitHub.
2. **Branch** off `main` with a descriptive name: `feature/`, `bugfix/`, `chore/`, `docs/`, or `marketplace/<item-name>`.
3. **Commit** in logical units. Conventional commit prefixes (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) help us write release notes.
4. **Open a PR** against `main`. The PR template will ask for motivation, changes, testing, and ADRs affected — fill it in honestly. "ADRs affected: none" is a valid answer when true.
5. **Iterate** on review. Code review is a conversation, not a gate. Disagreement is fine — articulate the trade-off and we'll figure it out.
6. **Squash or rebase** before merge if requested. We prefer clean history but won't hold up a good change over commit hygiene.

## Reviewing your own contribution

Before opening the PR:

- [ ] `make build && make check` succeeds locally.
- [ ] Smoke tests relevant to your area pass.
- [ ] If you added a marketplace item, you tested install + uninstall in `tests/sandbox.sh`.
- [ ] If you touched a slash command (`templates/.claude/commands/*.md`), you ran it in a real Claude Code session.
- [ ] If you affected an ADR, you updated it (or created a new one) in this PR.
- [ ] Bash 3.2 compatibility holds for any `src/` changes.
- [ ] No commented-out code, no `TODO` without context, no debug prints.

## Getting help

- **Open an issue** — we have templates for bugs, features, and "I want this in the marketplace" suggestions.
- **Existing ADRs** are the canonical answer for "why is it like this?" Read them before proposing a different way.
- **PRs welcome even if you're unsure** — open a draft PR and ask. Better to have a conversation around real code than a long Slack thread.

Welcome aboard.
