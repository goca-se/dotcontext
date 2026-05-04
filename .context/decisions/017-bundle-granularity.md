# ADR-017: Bundle Granularity (Atomic Items)

**Status:** Accepted
**Date:** 2026-04-30
**Version:** 1.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** marketplace TUI users, dotcontext maintainers

## Context

Several Layer 2 commands depend on extracted agent files or skills:

- `/code-review` requires 3 agents under `.claude/agents/code-review/`
- `/fix-bug` requires 5 agents under `.claude/agents/fix-bug/` plus the `bug-reproduction` skill
- `/create-pr` and `/pr-comment` share the `git-platform` skill

If the TUI lets users select the command without its agents, the command silently breaks at runtime ("Read .claude/agents/code-review/compliance-checker.md → file not found"). The user has no way to discover the missing dependency from the TUI.

## Decision

Treat each item with dependencies as an **atomic bundle**: one selectable unit in the TUI, all-or-nothing on install/remove.

### Item types in `manifest.json`

- `command-bundle` — a slash command plus all required agents and skills, listed in a single `files` array
- `skill` — a single skill file (rarely standalone, but possible)
- `mcp` — config entry for `.mcp.json` / `settings.json`
- `external-cli` — a binary (gh, glab) installed via OS package manager
- `hook` — a hook entry in settings.json plus optional script
- `script` — a standalone script (statusline.sh, notify.sh)

### Atomicity rule

A `command-bundle` install copies **every** file in its `files` array. If any copy fails, the install rolls back: all files written so far are deleted, lockfile is not updated, error is reported with the failing file.

### Shared dependencies

When two bundles share a skill (e.g., `create-pr` and `pr-comment` both depend on `git-platform`), the manifest expresses this via `depends_on`:

```json
{
  "id": "create-pr",
  "type": "command-bundle",
  "files": [{ "src": "templates/.claude/commands/create-pr.md", "dest": ".claude/commands/create-pr.md" }],
  "depends_on": ["git-platform-skill"]
}
```

The bundle resolver (`src/lib/marketplace/bundle.sh`) walks `depends_on` recursively and produces the union of files. Installing `create-pr` installs `git-platform-skill` if not already present. Removing `create-pr` removes `git-platform-skill` **only if** no other installed item still depends on it (reverse-reference check via lockfile).

### Why not separate items per agent

Selecting "code-review.md" without "compliance-checker.md" is a broken state. Exposing agents as individually selectable creates a footgun. The user value is "I want code review"; the implementation detail is "code review needs these 3 agents."

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Each file is a selectable item | Maximum flexibility | User can install broken combinations; TUI floods with files | Footgun |
| Atomic bundles (chosen) | User picks intent; consistent state | Can't install partial bundles (e.g., command without one specific agent) | Best UX/safety balance |
| Bundle + advanced "expand bundle" mode | Best of both | Doubles TUI complexity; maintenance burden | Over-engineered for v1 |

## Trade-offs Accepted

- **No per-agent install.** A user who wants `/code-review` without the `bug-detector` agent can't get that from the TUI. They must install the bundle then delete the agent file (and accept the broken state). We document this is unsupported.
- **Reverse-reference check on remove is O(N) over installed items.** With <100 installed items, this is fine. Documented as acceptable.
- **Dependencies are static in the manifest, not runtime-detected.** If a maintainer adds an agent to `/code-review` and forgets to update the manifest, the bundle ships incomplete. Mitigated by `make validate-manifest` checking that all referenced source files exist.

## Validation Criteria

- Installing `code-review` produces all 4 expected files (1 command + 3 agents); lockfile reflects all 4.
- Removing `code-review` removes all 4 files; lockfile entry gone.
- Installing `create-pr` then `pr-comment` results in a single copy of the `git-platform` skill (deduped via `depends_on`).
- Removing `create-pr` while `pr-comment` is still installed leaves `git-platform` skill intact.
- A failed install (simulated via permission error mid-bundle) leaves no partial files behind.

## Consequences

- **Positive:** consistent runtime state — if a bundle is installed, all its dependencies are present. TUI is comprehensible: one row = one capability.
- **Negative:** less flexibility for power users; manifest authoring requires care (forgotten dependency = broken bundle).
- **Risks:** circular `depends_on` would loop the resolver. Mitigated by validation in `make validate-manifest` (DAG check).

## Related ADRs

- ADR-012: Agent File Extraction Pattern (defined per-file agents; this ADR re-bundles them at distribution)
- ADR-015: Two-Layer Distribution Model (bundles are the unit of Layer 2 distribution)
- ADR-016: Lockfile Format and Scope Resolution (lockfile records bundle as one entry with its `files` array)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-30 | Initial decision |
