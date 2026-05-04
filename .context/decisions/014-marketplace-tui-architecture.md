# ADR-014: Marketplace TUI Architecture

**Status:** Accepted
**Date:** 2026-04-30
**Version:** 1.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** dotcontext maintainers, end users running `dotcontext` in terminals across macOS / Linux / WSL

## Context

dotcontext init currently dumps every command, agent, skill, statusline, hook, and MCP question into the user's project. The user has no opportunity to choose. Two questions emerged:

1. Where does the user choose what to install?
2. How is that experience implemented?

Three implementation options were considered:

- **Native Claude Code `/plugin` system** — Claude Code already supports plugins. We could distribute dotcontext items as plugins.
- **Bash-native TUI inside dotcontext** — Build our own selector, modeled after `lib/ui/` in `tw93/Mole`.
- **Hybrid** — Use `/plugin` for some items, bash TUI for CLIs/scripts.

The `/plugin` route fragments the experience — users would learn two systems, and `/plugin` does not cover external CLIs (`gh`, `glab`) or shell scripts (`statusline.sh`). The hybrid route doubles maintenance surface. dotcontext's identity has always been "one bash script, one curl install" (ADR-001).

## Decision

Build a bash-native TUI in `src/lib/ui/` that runs inside the same single-executable distribution. The TUI is the entry point when `dotcontext` is invoked with no arguments.

### Components

- `src/lib/ui/menu_paginated.sh` — paginated list, dynamic height via `tput lines` / `stty size`, alt-screen, arrow navigation
- `src/lib/ui/multi_select.sh` — checkbox toggling with space
- `src/lib/ui/detail_pane.sh` — side panel showing description, dependencies, current scope
- `src/lib/ui/confirm.sh` — y/N prompts (consolidates existing `src/core/ui.sh` helpers)
- `src/lib/ui/spinner_alt.sh` — spinner that coexists with alt-screen
- `src/lib/ui/tabs.sh` — Browse / Installed / Status tab header

The TUI is invoked through `src/commands/browse.sh` (an internal orchestrator, **not** exposed as `dotcontext browse` — entry is no-args).

### Reference

We mirror primitives from `tw93/Mole`'s `lib/ui/` (Bash 3.2 compatible, public-domain reference patterns), not a dependency.

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Native `/plugin` system | Less code; standard discovery | Doesn't cover CLIs / scripts; users learn two systems; loses dotcontext identity | Fragments UX |
| Hybrid (`/plugin` + bash TUI) | Best of both | Two install paths to maintain; double the bug surface | Maintenance cost |
| Use `gum` / `dialog` / `whiptail` | Mature, polished | External dependency breaks ADR-001 (single bash binary, curl-installable) | Distribution constraint |
| Bash-native TUI (chosen) | Single binary; full control over UX; covers all item types | Hand-rolled; risk in legacy terminals | Best fit for dotcontext's distribution model |

## Trade-offs Accepted

- **Hand-rolling TUI primitives in Bash 3.2** is harder than picking up Go / TypeScript with mature TUI libraries. We accept this in exchange for keeping `curl | bash` install and zero runtime dependencies.
- **Some terminals will render imperfectly** (legacy xterm without alt-screen, Windows ConEmu edge cases). We accept rendering fidelity is best-effort and provide a degraded fallback (simple line-based menu) when capability detection fails.
- **No clipboard, no fuzzy search initially.** First version ships a categorized list with multi-select. Filter / search lands later if usage justifies.

## Validation Criteria

- TUI launches in under 200 ms on commodity hardware (no perceptible lag vs. the user pressing the binary).
- Smoke tests pass on macOS Terminal.app, iTerm2, xterm, gnome-terminal, and Windows Terminal (via WSL).
- Bundle size remains under 200 KB after adding `lib/ui/*` (was ~60 KB pre-marketplace).
- Issue tracker shows no unresolved "TUI is unusable on terminal X" reports six months after release.

## Consequences

- **Positive:** dotcontext remains a single bash script with one install path; the user-facing surface (no-args = TUI, plus `init`/`update`) is small and consistent.
- **Negative:** TUI bugs are now part of dotcontext's bug surface; bash 3.2 limits expressiveness (no associative arrays, no `read -e` portability).
- **Risks:** Legacy terminal incompatibility; mitigated by capability detection + degraded fallback.

## Related ADRs

- ADR-001: Single Bash Executable Architecture (constrains us to bash distribution)
- ADR-007: CLI Simplification (no-args = TUI is the natural extension)
- ADR-015: Two-Layer Distribution Model (defines what the TUI manages)
- ADR-017: Bundle Granularity (defines what a single TUI selection represents)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-30 | Initial decision |
