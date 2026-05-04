# ADR-016: Lockfile Format and Scope Resolution

**Status:** Accepted
**Date:** 2026-04-30
**Version:** 1.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** dotcontext TUI implementers, future upgrade-feature implementers, end users (indirectly — lockfile drift = confusion)

## Context

The Layer 2 marketplace (ADR-015) lets users install items into either a project (`<repo>/.claude/`) or globally (`~/.claude/`). dotcontext needs to remember:

- Which items are installed in which scope
- What version was installed (so we can later offer upgrades)
- Which files belong to each item (so we can remove cleanly without touching unrelated files)
- When the install happened (for migration / debugging)

Without state, the TUI can't honestly answer "what's installed?" and `remove` becomes guesswork.

## Decision

Maintain a **lockfile per scope**:

- **Local lockfile:** `<repo>/.context/.dotcontext-state.json` — items installed into the current project
- **Global lockfile:** `~/.dotcontext/state.json` — items installed into `~/.claude/`

### Schema

```json
{
  "$schema_version": "1.0",
  "items": [
    {
      "id": "code-review",
      "version": "1.0.0",
      "scope": "local",
      "installed_at": "2026-04-30T14:32:11Z",
      "files": [
        ".claude/commands/code-review.md",
        ".claude/agents/code-review/compliance-checker.md",
        ".claude/agents/code-review/bug-detector.md",
        ".claude/agents/code-review/security-analyst.md"
      ]
    },
    {
      "id": "atlassian-mcp",
      "version": "1.0.0",
      "scope": "global",
      "installed_at": "2026-04-30T14:33:02Z",
      "settings_keys": ["mcpServers.atlassian"]
    },
    {
      "id": "gh-cli",
      "version": "auto-registered",
      "scope": "machine",
      "installed_at": "2026-04-30T14:34:10Z",
      "package_manager_used": "brew"
    }
  ]
}
```

### Field semantics

- `id` — matches `id` in `marketplace/manifest.json`
- `version` — exact semver from manifest at install time, or `"auto-registered"` for migrated items (ADR-018)
- `scope` — `"local"`, `"global"`, or `"machine"` (CLIs)
- `installed_at` — ISO 8601 UTC
- `files` — relative paths from scope root (`<repo>` for local, `~` for global). Used by `remove` to delete only what we installed.
- `settings_keys` — for items that mutate `settings.json` / `.mcp.json` (MCPs, hooks). Used by `remove` to delete only the keys we added.
- `package_manager_used` — for `external-cli` items, records `brew` / `apt` / `dnf` / `winget` so `remove` can call the matching uninstall command.

### Scope resolution rules

| Item type | Allowed scopes | Default |
|-----------|---------------|---------|
| `command-bundle` | local, global | local |
| `skill` | local, global | local |
| `mcp` | local, global | local (writes `.mcp.json`) or global (writes `~/.claude/settings.json`) |
| `hook` | local, global | local |
| `script` | local, global | local |
| `external-cli` | machine | machine (system-wide) |

The user toggles scope per item in the TUI (`g` / `l` keybinding). The default for each item type is conservative (local where possible) so a user who skips the toggle gets project-level isolation.

### Determining "current project"

`local` is anchored to the current working directory if it contains `.context/` (i.e., dotcontext was initialized here). Otherwise the TUI prompts: "Not in a dotcontext project. Install globally instead? [Y/n]".

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| `{name, scope}` only | Minimal | No way to upgrade (no version), can't clean-remove (no `files`) | Too thin |
| `{name, scope, version, timestamp, files}` (chosen) | Enables upgrade + clean remove + migration | Slightly more bytes per entry | Right size |
| Add content hash per file | Detects drift (user edited the file) | Extra computation; we don't act on drift today | YAGNI; can add later if needed |
| Store lockfile inside `.claude/` | Co-located with managed files | Pollutes `.claude/` (Claude tooling may see it); risk of accidental edit | `.context/` is the dotcontext domain |
| Single global lockfile (no per-scope split) | One source of truth | Project-scoped state in user's home is wrong (uninstalls wouldn't move with `git clone`) | Local lockfile must travel with project |

## Trade-offs Accepted

- **Two lockfiles can drift.** A user could edit `.claude/commands/code-review.md` after install; the lockfile won't notice. We accept this — content hashing is deferred until upgrade tooling needs it.
- **`.dotcontext-state.json` is checked into git by default.** This is intentional: it's part of project state, like `package-lock.json`. Users who don't want this can `.gitignore` it; documented in the README.
- **No partial-install recovery.** If install crashes mid-bundle, the lockfile may not reflect reality. Mitigation: write lockfile *after* file copy succeeds, and `remove` is forgiving of missing files.

## Validation Criteria

- Install + remove of every item type leaves the lockfile and filesystem in matching states (verifiable via comparison script).
- A `git clone` of a project with `.dotcontext-state.json` checked in lets the new clone see installed items in the TUI Installed tab without re-running `init`.
- Global install of `atlassian-mcp` writes only `~/.claude/settings.json`; does not touch any project's `.mcp.json`.
- Switching scope of an existing item (uninstall global → install local) results in lockfile entries in both files reflecting the move (old removed, new added).

## Consequences

- **Positive:** TUI can honestly enumerate installed items; clean removal is possible; future upgrade feature has the version + file list it needs.
- **Negative:** Two lockfiles to keep in sync; lockfile in `.context/` adds one more file to git history.
- **Risks:** Lockfile corruption (manual edit, partial write). Mitigated by JSON validation on read + atomic write (write to temp, rename).

## Related ADRs

- ADR-002: Template Download Strategy (lockfile is the source of truth for what was downloaded)
- ADR-003: Safe Update Behavior (lockfile-tracked items behave differently from untracked)
- ADR-015: Two-Layer Distribution Model (lockfile only tracks Layer 2)
- ADR-017: Bundle Granularity (a lockfile entry represents one atomic bundle)
- ADR-018: Existing User Migration via Auto-Registration (uses `version: "auto-registered"`)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-30 | Initial decision |
