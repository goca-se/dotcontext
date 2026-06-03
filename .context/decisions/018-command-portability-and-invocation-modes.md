# ADR-018: Command Portability & Invocation Modes (phase 2b plan)

**Status:** Proposed
**Date:** 2026-06-03
**Deciders:** Nicholas (Gocase)

## Context

ADR-016/017 made instructions, skills, and hooks multi-agent. The remaining piece (phase 2b) is
porting the 12 slash commands. Two facts shape the design:

1. **Commands and skills have converged** (Claude Code): a `/x` command is effectively a skill with
   `disable-model-invocation: true`. Skills (`SKILL.md`) port cleanly to all six agents (ADR-017);
   classic per-repo commands do not (Codex prompts are global, Cursor has no file-based slash command).
2. **Every agent ships a structured-question tool** (ADR-016 correction): Claude `AskUserQuestion`,
   Codex `request_user_input`, opencode `question`, Gemini `ask_user`, Copilot `ask_user`, Cursor
   `cursor/ask_question`. So requirement-gathering (ADR-005) is satisfiable on every agent.

The tempting shortcut — "make everything a skill" — is **unsafe**: skills are model-auto-invocable,
and `disable-model-invocation` (explicit-only) is honored only by Claude and Cursor. Auto-firing a
side-effecting command (`/commit`, `/create-pr`) on the other agents would be a foot-gun.

## Decision

### 1. Each artifact declares an invocation mode

- **`skill`** — auto-discoverable (model invokes by `description`) **and** explicitly invocable. For
  read-mostly knowledge/analysis with no dangerous side effects.
- **`command`** — explicit-only. For deliberate, side-effecting, or outward-facing actions.

Classification (skills for knowledge, commands for action):

| Mode `skill` | Mode `command` (explicit-only) |
|---|---|
| `bug-reproduction`, `batch-operations`, `git-platform` (existing guides) | `setup-context`, `generate-prp`, `execute-prp`, `commit`, `create-pr`, `pr-comment`, `add-decision`, `add-skill`, `add-command` |
| **`code-review`**, **`deep-context`** (read-mostly analysis — promoted from command) | `fix-bug` (makes changes; leans on the `bug-reproduction` skill) |

Rationale for the promotions: `code-review` and `deep-context` are read-mostly, and "review my changes"
/ "help me understand X" are natural auto-triggers — discovery adds value with no side-effect risk, and
the explicit `/name` still works.

### 2. Emit per agent by mode

- `skill` mode → `SKILL.md` (already ports to all six — ADR-017).
- `command` mode → each agent's **explicit** primitive: Claude command, opencode command, Copilot
  prompt file, Gemini custom command (TOML), Cursor skill + `disable-model-invocation`, Codex prompt
  (global `~/.codex/prompts/`, namespaced). Where an agent only offers auto-skills, use its explicit
  flag if honored, otherwise fall back to documenting the workflow in `AGENTS.md`.

### 3. Portable `{{ASK}}` directive

Command/skill bodies express requirement-gathering with a portable `{{ASK: question | optA | optB }}`
directive. At emit time it renders to each agent's **native** structured-question tool — it does **not**
degrade to free text. This satisfies ADR-005's clarity-assessed questioning on every agent.

## Consequences

- **Positive:** preserves the safe boundary (knowledge = skill, action = command); no side-effecting
  auto-invocation; `{{ASK}}` keeps the ADR-005 contract everywhere.
- **Negative:** the emitter must implement per-agent command formats + the `{{ASK}}` renderer; Codex
  commands remain global; Cursor commands ride on the skill+flag path.

## Alternatives Considered

1. **All artifacts as auto-skills** — rejected: unsafe (auto-firing side effects; `disable-model-invocation`
   not universal).
2. **All as classic commands** — rejected: don't port (Codex global, Cursor none).
3. **Free-text fallback for `{{ASK}}`** — rejected: unnecessary, every agent has a native question tool.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 (proposed) | 2026-06-03 | Initial plan for phase 2b |

## Related
- ADR-005: Mandatory AskUserQuestion (clarity assessment) — `{{ASK}}` is how it's satisfied cross-agent
- ADR-016: Multi-agent harness (instructions)
- ADR-017: Harness selection, skills & hooks portability
