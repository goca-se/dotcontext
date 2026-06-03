# ADR-017: Harness Selection, Skills & Hooks Portability

**Status:** Accepted
**Date:** 2026-06-03
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

ADR-016 made the project-instructions file (`AGENTS.md`) multi-agent. Two follow-ups remained:
**skills** and **hooks**. Research (June 2026) overturned an earlier assumption: **all six target
agents now implement the open Agent Skills (`SKILL.md`) standard, ship lifecycle hooks, and expose a
model-callable structured-question tool** (so the `AskUserQuestion` premise in ADR-016's first draft
was wrong — corrected there).

Skills directory coverage:

| Reads `.agents/skills/` | Reads `.claude/skills/` |
|-------------------------|--------------------------|
| Codex, opencode, Gemini, Copilot, Cursor | Claude, opencode, Copilot, Cursor |

No single directory covers all six: **Claude only reads `.claude/skills/`**, and **Codex/Gemini do
not read `.claude/skills/`**.

A separate problem surfaced: the old `init` emitted **all** of `.claude/` (commands, agents,
statusline, settings) plus `CLAUDE.md` unconditionally — junk for a user who only runs Codex or
Gemini.

## Decision

### 1. Harness selection — only emit what the chosen agents use

`dotcontext init` resolves a set of harnesses and emits files **only** for them:
- **Interactive** (default): confirm each detected agent (default = detected set).
- **`--agents claude,codex`** flag: non-interactive/scripted selection (a deliberate, scoped
  exception to the minimal-CLI rule of ADR-007, for spec-kit `--integration` parity).
- **`--yes`**: all detected agents (fallback to `claude` if none).

Emission gating:
- `AGENTS.md` (canonical instructions) + `.context/` skeleton + MCP → **always** (harness-agnostic).
- `CLAUDE.md` stub + **all of `.claude/`** (commands, agents, statusline, `.claudeignore`) → **only if
  Claude is selected**.
- `GEMINI.md` stub → only if Gemini selected.
- A Codex-only project therefore gets just `AGENTS.md` + `.agents/skills/` + a Codex hook — no `.claude/`.

### 2. Skills — `.agents/skills/` canonical, mirrored to `.claude/skills/`

The shared `SKILL.md` files are emitted to the physical directory matching the selection:
- Claude selected → physical `.claude/skills/`; if an `AGENTS.md`-reading agent is also selected,
  `.agents/skills/` is a symlink to it (copy fallback for filesystems without symlinks).
- Claude not selected → physical `.agents/skills/`.

dotcontext owns these files, so a single physical copy + symlink avoids drift (no `@import` exists for
skills, unlike instructions).

### 3. Hooks — a notification hook per selected harness

Each selected harness gets a "task finished / needs attention" notification wired in its native config:
- Claude → `.claude/settings.json` (existing: notify + tool-failure-guard).
- Codex → `.codex/hooks.json`; Gemini → `.gemini/settings.json`; Copilot → `.github/hooks/dotcontext-notify.json`;
  Cursor → `.cursor/hooks.json`; opencode → `.opencode/plugins/dotcontext-notify.js` (opencode has no
  declarative hooks — only JS/TS plugins).
- All point at a shared, **arg-driven** `notify.sh` (it takes title/message/sound as args and ignores
  stdin, so the same script works regardless of each agent's hook JSON contract). Create-only — never
  clobbers an existing agent config.

**Scope limits (intentional):** only the **notification** hook ports. The richer
`tool-failure-guard` stays **Claude-only** (it depends on Claude's `PostToolUseFailure` semantics, which
don't map uniformly). Non-Claude hook configs are validated as well-formed (JSON/TOML/JS) but are
**best-effort** — they are not end-to-end tested against each agent runtime.

## Consequences

### Positive
- No junk: a project only carries files for the harnesses it actually uses.
- Skills and notification hooks work across all six agents from shared sources.
- Confirms command portability (future ADR-005 v2.0) is viable — every agent has a native
  structured-question tool.

### Negative
- Per-agent hook configs are best-effort (not runtime-tested per agent); event-name/semantics differ
  (e.g. Gemini uses `AfterAgent`, not `Stop`).
- `tool-failure-guard` remains Claude-only.
- A `--agents` flag widens the CLI surface (scoped exception, justified above).

## Alternatives Considered

1. **Emit everything for all agents always** — rejected: dumps junk (the problem this fixes).
2. **One skills dir for all** — impossible: Claude and Codex/Gemini read disjoint directories.
3. **Duplicate skill copies per ecosystem** — rejected: drift; symlink keeps one source.
4. **Port `tool-failure-guard` everywhere** — rejected for now: no uniform failure-event semantics.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-03 | Initial decision (harness selection, skills, notification hooks) |

## Related
- ADR-016: Multi-agent harness (instructions file) — this builds on it
- ADR-005: Mandatory AskUserQuestion — a future v2.0 will render `{{ASK}}` to each agent's native question tool
- ADR-007: CLI simplification — `--agents` is a scoped exception
