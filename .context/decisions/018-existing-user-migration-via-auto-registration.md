# ADR-018: Existing User Migration via Auto-Registration

**Status:** Accepted
**Date:** 2026-04-30
**Version:** 1.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** users on dotcontext < v0.15 with already-installed Layer 2 items, dotcontext maintainers

## Context

Existing dotcontext users have files in `.claude/commands/`, `.claude/agents/`, and `.claude/skills/` that were created by the old all-in-one `dotcontext init`. After the marketplace lands (ADR-015), those files become "Layer 2" items — but the user's `.dotcontext-state.json` is empty, so the TUI thinks nothing is installed.

We must avoid:

- **Breaking the user's setup** — files they rely on must keep working
- **Forcing manual reinstallation** — would frustrate users
- **Surprise modifications** — files they customized must not be touched

We need a migration that recognizes existing files and registers them in the lockfile **without modifying anything on disk**.

## Decision

On the first `dotcontext update` after upgrading to v0.15+, run **silent auto-registration**:

1. Read `marketplace/manifest.json` (the embedded one).
2. For each item in the manifest, check whether **all** files in its `files` array exist at the expected paths in `.claude/` (local) and `~/.claude/` (global).
3. If yes, write a lockfile entry: `{id, version: "auto-registered", scope, installed_at: <now>, files: [...]}`.
4. Never touch the files themselves — only populate the lockfile.
5. After scanning, print a single summary line: `Detected N items from previous installation. Registered in marketplace state. Run 'dotcontext' to manage.`

### Trigger

Auto-registration runs once, gated by a marker file `~/.dotcontext/migration-v015-done`. Subsequent runs check the marker and skip. The marker exists per-user (not per-project) — re-running migration in another project overwrites the local lockfile entries (idempotent), but the global one is migrated only once.

### Detection rule (avoiding false positives)

A file path match is **not enough** — a user might have an unrelated `.claude/commands/code-review.md` they wrote themselves. We require **all** files in the bundle's `files` array to exist *and* match a registered SHA-256 hash from a known dotcontext template version.

The CLI ships a small embedded `migration-hashes.json` listing hashes for every template file across recent versions (v0.10 through v0.14). If a file matches *any* known hash, it's recognized; if it doesn't match any, the user has customized it and we still register it (the user wants to keep their version, and our `remove` semantics will respect their copy).

If the bundle is partially present (some files match, some missing), we **do not** register — partial installs aren't safe to assume.

### What we don't do

- **No file rewrites.** Even if the user has an outdated template, we don't rewrite. Upgrades come later via the explicit upgrade feature (out of scope here).
- **No prompts during migration.** Silent + summary line. Adding prompts on first update would frustrate users.
- **No migration of MCPs from `~/.claude/settings.json`.** Detecting MCP entries is doable; migrating is risky if the user added MCPs manually. Out of scope; user can re-select via TUI if they want them tracked.

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Auto-register (chosen) | Zero-friction; user keeps their setup | Risk of false positive (rare given hash check) | Best balance |
| Migration TUI on first update | User confirms each item | Forces interaction on update; annoying | High friction |
| Passive notice ("you may have items, run `dotcontext` to scan") | No automatic action | Many users will never see the notice; lockfile stays wrong | Silent failure mode |
| Force re-init | Clean slate | Destructive; loses customization | Unacceptable |

## Trade-offs Accepted

- **Hash database has to be maintained.** Each release that changes a template adds a hash entry. Mitigated by `make` target that regenerates hashes from `templates/` at release time.
- **A user with a heavily customized template won't match a known hash and will still be registered.** This is intentional: their version is *their* version. Our `remove` deletes by path — it'll delete their customized file, but only if the user explicitly chooses to remove that item from the TUI. We document this in `MIGRATION.md`.
- **No undo for migration.** If migration registers something the user wishes hadn't been registered, they can manually edit `.dotcontext-state.json` (it's plain JSON). Documented as the supported recovery path.

## Validation Criteria

- A v0.14 project with all 12 commands, all agents, and 3 skills: after `dotcontext update`, lockfile contains entries for the 6 dream-team Layer 2 commands (Layer 1 commands stay managed by init, not in the lockfile). All Layer 2 agents listed in the bundle entries.
- A project with a partially-installed bundle (e.g., command file present but agent files missing) is **not** registered for that bundle.
- Re-running `dotcontext update` after migration is a no-op (marker prevents re-run).
- A project with a customized `code-review.md` (hash mismatch but file path matches) **is** registered — the user wants their files tracked.
- A project with a hand-written file at the bundle path that has *zero* connection to dotcontext: still registered if the path matches *and* the bundle's other files happen to also exist. Documented as a known limitation; the user can manually remove the entry.

## Consequences

- **Positive:** zero-friction upgrade; no broken setups; users discover the new TUI through the post-update message.
- **Negative:** complexity in maintaining `migration-hashes.json`; edge case where a hand-rolled bundle could be detected (rare).
- **Risks:** false positive registration leading the user to "remove" via TUI and losing custom work. Mitigated by `remove` confirmation prompts and clear lockfile docs.

## Related ADRs

- ADR-002: Template Download Strategy (migration is one-time, not a download)
- ADR-003: Safe Update Behavior (auto-registration extends "safe update" to existing files)
- ADR-015: Two-Layer Distribution Model (migration only touches Layer 2)
- ADR-016: Lockfile Format and Scope Resolution (migration writes `version: "auto-registered"`)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-30 | Initial decision |
