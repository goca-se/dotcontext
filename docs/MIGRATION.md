# Migration: dotcontext v0.14 → v0.15

This release introduces the **Marketplace TUI** and a **two-layer distribution model**. It includes breaking CLI changes. This guide explains how to upgrade.

## TL;DR

```bash
dotcontext update    # CLI updates first; auto-migration runs once
dotcontext           # opens the new marketplace TUI
```

You don't need to reinstall anything. Auto-registration (silent) tells the new TUI which Layer 2 items you already have.

## What changed

### `dotcontext init` is now strictly minimal

`init` creates **only the absolute bootstrap**:

- `.context/` skeleton (CONTEXT.md, decisions/, prp/, discoveries/, bugs/)
- `CLAUDE.md`
- `.claudeignore`
- `/setup-context` — the single command that populates `.context/` from your codebase

**Everything else is Layer 2**, installed on demand from the marketplace TUI. That includes commands you may have relied on previously:

- `/add-decision`, `/add-skill`, `/add-command` (methodology helpers — were Layer 1 in pre-v0.15)
- `/commit`, `/deep-context` (+ 4 deep-context agents — were Layer 1 in pre-v0.15)
- `/code-review`, `/fix-bug`, `/create-pr`, `/pr-comment`, `/generate-prp`, `/execute-prp`
- MCPs (Atlassian, Grafana, Context7), external CLIs (`gh`, `glab`)
- Statusline, notification hook, skills (`bug-reproduction`, `git-platform`, `batch-operations`)

All 16 of these are in the **starter pack** — pressing `p` then `i` in the marketplace TUI installs all of them in one keystroke pair. Auto-registration on `dotcontext update` already preserves your existing files in the lockfile so they show up in the TUI's Installed tab.

See [ADR-015: Two-Layer Distribution Model](../.context/decisions/015-two-layer-distribution-model.md).

### `dotcontext doctor` and `dotcontext completion` are gone

Both print a deprecation notice and exit 0 for this release. They will be removed entirely in the next release.

- `doctor`'s functionality is now the **Status** tab in the TUI (run `dotcontext`).
- For shell completion, regenerate locally; instructions are in the README.

See [ADR-007 v2.0](../.context/decisions/007-cli-simplification.md).

### `dotcontext` (no args) opens the TUI

Previously, no-args printed help. Now it opens the marketplace TUI. Use `dotcontext --help` for help.

## What didn't change

- All your existing files in `.claude/` and `.context/` keep working.
- Your `.mcp.json` and `~/.claude/settings.json` are not modified.
- ADRs you've authored stay in v1.0 schema; new ADRs use v2.0 (coexistence is intentional — see ADR-019).
- `dotcontext init` and `dotcontext update` still work the way you expect.

## How auto-registration works

When you run `dotcontext update` after upgrading to v0.15+:

1. The CLI is updated.
2. Layer 1 templates are updated (same flow as before).
3. **Auto-registration scans** `.claude/` and `~/.claude/` for files belonging to known Layer 2 items in the manifest.
4. For any Layer 2 item whose **all** files are present, a lockfile entry is written with `version: "auto-registered"`.
5. A marker file (`~/.dotcontext/migration-v015-done`) prevents re-running migration.

You'll see one summary line:

```
Detected 8 item(s) from previous installation.
Registered in marketplace state. Run dotcontext to manage.
```

After that, the TUI's **Installed** tab shows everything you have.

## What auto-registration does NOT do

- It **does not modify any files on disk.** Files keep the version you have. If a newer version exists in the manifest, you can re-install through the TUI to get the update.
- It **does not register MCPs or hooks** that are already in `settings.json`. Those are too easy to misattribute (you might have added them manually). If you want them in the lockfile, install via the TUI; the existing entries will be reused.
- It **does not detect partial bundles.** If you have `code-review.md` but not all 3 of its agents, the bundle is not registered. Re-install via the TUI to get the missing files.

See [ADR-018](../.context/decisions/018-existing-user-migration-via-auto-registration.md) for the full migration semantics.

## How to install something new

After upgrading:

```bash
dotcontext
```

This opens the TUI. Three tabs:

| Tab | What it shows |
|-----|---------------|
| **Browse** | All marketplace items, by category. Multi-select with space; `g`/`l` toggles scope; `p` selects all 11 starter-pack items; `i` installs your selection. |
| **Installed** | Lockfile contents (what you've installed). Press `u` to uninstall the focused item. |
| **Status** | Layer 1 health, installed MCPs, CLI auth status. Replaces `dotcontext doctor`. |

Quit with `q`. Switch tabs with `tab` / `shift-tab`.

## Scope: local vs global vs machine

Each item has a current scope shown next to its checkbox:

- **`[L]` local** — installs into `<repo>/.claude/...` or `<repo>/.mcp.json`. Travels with the project (commit `.dotcontext-state.json` to git so others get it).
- **`[G]` global** — installs into `~/.claude/...` or `~/.claude/settings.json`. Available in all your projects.
- **`[M]` machine** — for external CLIs (`gh`, `glab`). Installed via your OS package manager.

Press `g` (global) or `l` (local) on the focused item to change. The default for each item is conservative — usually local.

## Rolling back

If something goes wrong, the lockfile is plain JSON and editable:

- Local: `<project>/.context/.dotcontext-state.json`
- Global: `~/.dotcontext/state.json`

To force migration to re-run, delete `~/.dotcontext/migration-v015-done` and run `dotcontext update`.

## Questions or issues

Open an issue at <https://github.com/goca-se/dotcontext/issues>.
