# ADR-016: Multi-Agent Harness via Adapter Registry

**Status:** Accepted
**Date:** 2026-06-02
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

dotcontext was built Claude-Code-first (ADR-004): a project-root `CLAUDE.md` plus `.claude/`
commands, agents, and skills. ADR-004 explicitly accepted "tightly coupled to Claude Code
(won't work with other AI tools)" as a tradeoff.

The toolkit's value — the curated project instructions, decisions, and skills — is agent-agnostic.
Coding agents have converged on a near-common convention: the **AGENTS.md** open standard
(Linux-Foundation-stewarded, plain Markdown, nearest-file-wins). GitHub's spec-kit ships per-agent
integrations; we want the same reach without abandoning the Claude-first ergonomics.

Research (2026) on where each agent reads its project instruction/memory file:

| Agent | Instructions file | Reads `AGENTS.md` natively? |
|-------|-------------------|-----------------------------|
| Claude Code | `CLAUDE.md` | No (but supports `@import`) |
| OpenAI Codex | `AGENTS.md` | Yes (originator) |
| opencode | `AGENTS.md` (also reads `CLAUDE.md`) | Yes |
| GitHub Copilot | `AGENTS.md` / `.github/copilot-instructions.md` | Yes (since Aug 2025) |
| Cursor (IDE + `cursor-agent` CLI) | `AGENTS.md` / `.cursor/rules/*.mdc` | Yes |
| Gemini CLI | `GEMINI.md` | No (but supports `@import`; configurable) |

## Decision

### 1. Extensible adapter registry

A registry (`src/setup/agents.sh`) declares each supported agent as a small record: `id`,
display name, detection command (`command -v`), instructions filename, and emit mode. Adding an
agent is one entry — nothing else in the toolkit hard-codes an agent. Initial set:
`claude, codex, opencode, gemini, copilot, cursor` (the Cursor entry covers both the IDE and the
`cursor-agent` CLI).

### 2. `AGENTS.md` is the single canonical source of project instructions

The real instruction content lives in **`AGENTS.md` at the repo root**. This natively covers
**codex, opencode, copilot, and cursor** with zero extra files. The two agents that don't read
`AGENTS.md` get thin **import stubs** pointing at it (both support `@import`):

- `CLAUDE.md` → `@AGENTS.md` (for Claude Code)
- `GEMINI.md` → `@AGENTS.md` (for Gemini CLI)

Single source, no duplication, no drift; each editor edits `AGENTS.md`.

### 3. Interactive agent detection (no new CLI flags)

`dotcontext init` detects which agent CLIs are installed and emits the matching instruction files;
in interactive mode it confirms the selection. `--yes` sets up all detected agents (falling back
to Claude when none are detected). This honors the minimal-CLI constraint (ADR-007) — no
`--agent` flag, the flow lives inside `init`.

### 4. Safe migration for existing projects

`dotcontext update` migrates legacy single-file projects: when a content-bearing `CLAUDE.md`
exists and `AGENTS.md` does not, it offers to make `AGENTS.md` canonical (move the content) and
leave `CLAUDE.md` as an `@AGENTS.md` stub. This is content-preserving and behavior-preserving for
Claude (it still reads the same content via the import).

### 5. Scope of this decision (phase 2a)

This ADR covers the **instructions file** only. Skills and hooks portability is addressed in
**ADR-017**; porting slash commands to each agent's native format is deferred to a later phase.

> **Correction (2026-06-03):** an earlier draft of this ADR claimed "Codex/Gemini/etc. have no
> structured-question API," used to justify a degraded `{{ASK}}` fallback. That premise is **false**.
> Current research (see ADR-017) confirms **all six agents ship a model-callable structured-question
> tool** (Claude `AskUserQuestion`, Codex `request_user_input`, opencode `question`, Gemini
> `ask_user`, Copilot `ask_user`, Cursor `cursor/ask_question`) **and** lifecycle hooks. So command
> portability (ADR-018) renders `{{ASK}}` to each agent's **native** question tool — it
> does not degrade to free text. The `--version --json` handshake (ADR-015) flips `multiagent: true`
> and lists supported `agents` as adapters land.

## Consequences

### Positive
- The toolkit works across Claude, Codex, opencode, Copilot, Cursor, and Gemini from one source.
- Adding a new agent is a single registry entry.
- Existing Claude-only projects keep working and migrate safely.

### Negative
- A root `AGENTS.md` plus possible `CLAUDE.md`/`GEMINI.md` stubs is slightly more surface than a
  lone `CLAUDE.md`.
- Import resolution depends on each agent honoring `@import`; agents that don't are covered by
  reading `AGENTS.md` directly, but a future agent that does neither would need a real copy.
- Command/skill portability is **not** solved here (phase 2b).

## Alternatives Considered

1. **Keep `CLAUDE.md` canonical, point `AGENTS.md` at it via `@import`** — rejected: Codex/Copilot/
   Cursor don't resolve `@import`, so they'd see a literal pointer instead of content.
2. **Symlinks (`AGENTS.md` → `CLAUDE.md`)** — rejected: fragile on Windows/WSL (ADR cross-platform rule) and in git.
3. **Full content copies per agent** — rejected: guarantees drift across files.
4. **Per-agent zip artifacts (old spec-kit model)** — rejected: doesn't fit the single-bash-executable + curl distribution (ADR-001/002).

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-02 | Initial decision (phase 2a: instructions file across agents) |

## Related
- ADR-004: Claude Code integration (this extends it beyond Claude)
- ADR-005: Mandatory AskUserQuestion (will get a v2.0 for command portability in phase 2b)
- ADR-007: CLI simplification (interactive detection, no new flags)
- ADR-015: Capability discovery & update awareness (the handshake this populates)
