# ADR-020: Marketplace Source Topology

**Status:** Accepted
**Date:** 2026-05-01
**Version:** 1.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** dotcontext maintainers, community contributors adding marketplace items, end users (indirectly — affects where they file issues)

## Context

ADR-014 introduced the marketplace TUI. ADR-015 v3 defined the strict Layer 1 / Layer 2 split. Neither said *where the marketplace catalog lives*. In the initial implementation (PR #5 on the dotcontext repo) the catalog (`marketplace/manifest.json`, schema, validator, Layer 2 templates) sat **inside the dotcontext repo**.

Three issues emerged from that choice in practice:

1. **Single PR funnel.** Adding a new marketplace item (e.g., a new MCP server entry) required a PR against the harness repo. Reviewers had to context-switch between harness changes and catalog additions.
2. **Contribution friction (perceived).** A casual contributor wanting to suggest "add Foo MCP" reads a CONTRIBUTING.md full of bash 3.2 constraints, ADR compliance, lib/ui architecture — most of which is irrelevant to their change. The repo *looks* harder to contribute to than the marketplace addition actually is.
3. **Repo bloat over time.** The harness repo carries ~30 Layer 2 template files today. A growing catalog (50+ items) would dilute the harness signal in `git log` and PR list.

A discussion with our tech lead concluded the catalog should live separately to lower the contribution bar and keep the harness focused.

## Decision

The marketplace catalog moves to a dedicated repo: **[goca-se/dotcontext-marketplace](https://github.com/goca-se/dotcontext-marketplace)**.

### What lives where

| File / directory | Repo |
|------------------|------|
| `manifest.json` + `manifest.schema.json` | **dotcontext-marketplace** |
| `scripts/validate-manifest.sh` | **dotcontext-marketplace** |
| `templates/.claude/commands/*.md` (Layer 2 — code-review, fix-bug, etc.) | **dotcontext-marketplace** |
| `templates/.claude/agents/*` (Layer 2 agents) | **dotcontext-marketplace** |
| `templates/.claude/skills/*` (Layer 2 skills) | **dotcontext-marketplace** |
| `templates/.claude/scripts/*` (Layer 2 scripts e.g. statusline) | **dotcontext-marketplace** |
| `src/` (CLI, lib/ui, lib/marketplace, lib/install) | **dotcontext** |
| `templates/.claude/commands/setup-context.md` (only Layer 1 command) | **dotcontext** |
| `templates/CLAUDE.md`, `templates/.context/`, `templates/.claudeignore` | **dotcontext** |
| Other tooling (`install.sh`, `dotcontext` binary, ADRs, docs) | **dotcontext** |

### How the CLI consumes the marketplace

`src/header.sh` defines:

```bash
MARKETPLACE_REPO="${DOTCONTEXT_MARKETPLACE_REPO:-goca-se/dotcontext-marketplace}"
MARKETPLACE_BRANCH="${DOTCONTEXT_MARKETPLACE_BRANCH:-main}"
MARKETPLACE_URL="https://raw.githubusercontent.com/${MARKETPLACE_REPO}/${MARKETPLACE_BRANCH}"
```

Manifest resolution (in order):

1. `$DOTCONTEXT_MANIFEST` (explicit override — for pinning a manifest version or tests)
2. `$DOTCONTEXT_MARKETPLACE_ROOT/manifest.json` (local clone — for development)
3. `$HOME/.dotcontext/cache/manifest.json` (cache from a prior fetch)
4. Fetch `$MARKETPLACE_URL/manifest.json` → cache → use

Layer 2 template fetches (`_mp_fetch_file` in `src/lib/install/command.sh`) follow the same `DOTCONTEXT_MARKETPLACE_ROOT` → `MARKETPLACE_URL` order.

### CI cross-repo

- **dotcontext** repo CI: `make check` (lib syntax + smoke tests if marketplace clone present).
- **dotcontext-marketplace** repo CI: `make validate-manifest` on every PR, plus an integration job that clones dotcontext, builds the binary, and installs 3 random items in a sandbox to catch drift.

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Same repo (status quo until now) | Atomic manifest ↔ files; single CI; no version skew; one CONTRIBUTING | High PR friction for catalog adds; harness PR list cluttered by catalog churn; harder to scale | The friction outweighs simplicity once the project intends to attract community catalog contributions |
| Separate repo (chosen) | Low bar for catalog PRs; harness stays focused; independent release cadence | Two CIs, two CONTRIBUTING; cross-repo drift risk; CLI needs URL config + cache | Acceptable cost given the contribution-friction benefit |
| Multi-source taps (Homebrew-style) | Decentralized; any user can publish | Trust model required (sandboxing arbitrary scripts); discovery problem; significant new infra | Premature for project's current scale; PRP excluded it explicitly |
| Plugin registry (npm-style) | Rich ecosystem possible | Massive infra (hosting, auth, moderation) | Overkill for ~21 items; would dwarf the project |
| Embedded manifest in binary | Zero network; CLI + catalog always in sync | Catalog update = CLI release; binary grows | Wrong cadence: we want catalog to evolve faster than the CLI |

## Trade-offs Accepted

- **Two CIs to maintain.** dotcontext PRs and marketplace PRs each have their own CI workflow. We accept this cost in exchange for the contribution-friction win.
- **Drift risk between repos.** A change to the manifest schema in marketplace must coordinate with a CLI release that understands it. Mitigations: schema version field, optional `min_cli_version` per item (future), integration smoke test in marketplace CI that uses the latest released CLI.
- **Two CONTRIBUTING.md files to keep aligned.** Each focused on its surface. Drift between them is possible. Mitigations: each file links to the other; PR description in either repo asks "does this affect the other repo?"
- **Catalog URL is now a moving target.** If we ever rename `goca-se/dotcontext-marketplace`, every installed dotcontext binary breaks. Mitigations: `MARKETPLACE_REPO` is env-overridable; we treat the URL as a stable API (only renamed via deprecation cycle with CLI defaulting to the new URL while honoring the old via fallback).
- **Cache invalidation is now a thing.** `$HOME/.dotcontext/cache/manifest.json` can go stale. Today: cached forever (`mp_manifest_refresh_cache` exists but isn't wired to a key). Mitigations: TUI `r` key (future), or a TTL on the cache (future). For now, users can `rm ~/.dotcontext/cache/manifest.json` to force a refresh.
- **For users without internet, the marketplace TUI requires a prior fetch.** Cached state covers the offline case once primed. Documented in MIGRATION.md.

## Validation Criteria

- Within 6 months: at least 3 PRs from external contributors land in `goca-se/dotcontext-marketplace` adding new items.
- Within 3 months: marketplace repo has > 5 stars (rough proxy for discoverability).
- Issue ratio: > 50% of "I want X in the marketplace" issues are filed in the marketplace repo, not dotcontext (suggests users found the right place).
- No data loss from drift: zero "manifest references file that doesn't exist" errors in production reports across 6 months.
- Cache hit rate (after we add basic telemetry, or measured manually): > 90% of TUI opens use cache, not network.

## Consequences

- **Positive:** clearer mental model for contribution; harness PR list focuses on harness changes; community can extend the catalog without core review friction; future split into multi-source taps (ADR-???) is easier to bolt on.
- **Negative:** two repos to coordinate; integration test boundary; cache adds complexity; "where do I file this?" question for new contributors.
- **Risks:** drift between schema (marketplace) and parser (CLI). Mitigations: schema version field, manifest validation in CLI on load, integration tests in marketplace CI.

## Related ADRs

- ADR-014: Marketplace TUI Architecture (defined the TUI; this ADR says where the catalog it reads lives)
- ADR-015 v3: Two-Layer Distribution Model (Layer 2 = marketplace; this ADR clarifies marketplace's physical location)
- ADR-002 v2: Template Download Strategy (extended here — Layer 2 download URL points at marketplace repo, not dotcontext)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-01 | Initial decision — split catalog into goca-se/dotcontext-marketplace |
