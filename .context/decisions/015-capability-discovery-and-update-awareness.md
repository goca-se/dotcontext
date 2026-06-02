# ADR-015: Capability Discovery & Update Awareness

**Status:** Accepted
**Date:** 2026-06-02
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

Two gaps surfaced while comparing dotcontext to github/spec-kit:

1. **No update awareness.** dotcontext only checked for a newer version when the user explicitly
   ran `dotcontext update`. spec-kit's `specify self check` surfaces "update available" passively.
2. **No machine-readable capability handshake.** spec-kit exposes `specify version --features --json`
   so a harness can discover what the tool supports before invoking it. This becomes important for
   the planned multi-agent work (ADR-016, forthcoming), where a harness must know whether features
   like `AskUserQuestion`, statusline, or multi-agent output are available.

A standing project constraint is to keep the CLI surface minimal — new flows belong inside existing
commands, not as new top-level subcommands (see ADR-007).

## Decision

1. **Update awareness lives inside `doctor`, not a new subcommand.** `dotcontext doctor` ends with a
   best-effort check that compares the installed `VERSION` against the latest GitHub release and prints
   `update available: X → Y` (warning) or `up to date` (pass). The lookup is cached for one day under
   `${XDG_CACHE_HOME:-~/.cache}/dotcontext/` and is silent when offline — it never fails `doctor`.
   Shared helpers `fetch_latest_version()` and `version_gt()` live in `src/core/utils.sh`.

2. **`--version` gains `--features` and `--json`.** Plain `--version` is unchanged. `--features` prints
   a human-readable capability list; `--json` emits a machine-readable handshake (name, version, repo,
   commands, and a `capabilities` object) with **no jq dependency** (hand-built JSON). The current
   `capabilities.multiagent` is `false` and `agents` is `["claude"]`; these flip when ADR-016 lands.

## Consequences

### Positive
- Users learn about updates during the health check they already run, with zero new subcommand.
- Agents/harnesses can gate behavior on `--version --json` instead of guessing.
- The capability object gives the multi-agent work a ready-made place to advertise support.

### Negative
- The capability flags are hand-maintained in `cmd_version`; they must be kept honest as features land.
- `doctor` makes a network call (cached, best-effort) it did not before.

## Alternatives Considered

1. **New `dotcontext check` subcommand** (1:1 spec-kit parity) — rejected: conflicts with the minimal-CLI
   constraint (ADR-007).
2. **Background/startup update nag on every command** — rejected as intrusive; `doctor` is the natural,
   opt-in touchpoint.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-02 | Initial decision |

## Related
- ADR-007: CLI simplification
- ADR-005: Mandatory AskUserQuestion (a capability that does not port to other agents)
- ADR-016: Multi-agent harness support (forthcoming) — will consume the capability handshake
