# ADR-018: Command Portability & Invocation Modes (phase 2b plan)

**Status:** Accepted
**Date:** 2026-06-03
**Version:** 1.0
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

### 2. Emit per agent by mode — **hybrid** (chosen)

- `skill` mode → `SKILL.md` (already ports to all six — ADR-017).
- `command` mode → **native command/prompt files where the format is markdown-compatible and safe**,
  and **`AGENTS.md` documentation everywhere else**:
  - **Claude** → `.claude/commands/<name>.md` (slash command)
  - **opencode** → `.opencode/command/<name>.md`
  - **Copilot** → `.github/prompts/<name>.prompt.md`
  - **Gemini, Cursor, Codex** → a **`## Workflows`** section in `AGENTS.md` (lists each workflow + when
    to use). Rejected per-agent transforms (Gemini TOML, Cursor skill+flag, Codex global prompts) as
    high-effort, format-divergent, and not runtime-verifiable here — the `AGENTS.md` section makes the
    workflows usable on those agents without fragile generation.

The canonical bodies are the existing `templates/.claude/commands/*.md`; opencode/Copilot receive copies
(create-only). The `AGENTS.md` Workflows section also instructs every agent to use its **native
structured-question tool** for clarification.

> **Note:** the `code-review`/`deep-context` skill-mode promotion (item 1) is recorded but **not yet
> applied** — they currently ship as commands. Converting them to discoverable `SKILL.md` is a small
> follow-up within phase 2b.

### 3. Portable `{{ASK}}` directive

Command/skill bodies express requirement-gathering with a portable `{{ASK: question | optA | optB }}`
directive. Because **every** agent ships a native structured-question tool (Context fact 2), this is an
**authoring convention**, not a runtime transformer: bodies say "ask the user via your structured-question
tool: …", and each agent's model uses its own (`AskUserQuestion` / `ask_user` / `question` / …). It does
**not** degrade to free text, and satisfies ADR-005's clarity-assessed questioning on every agent.

### 4. Skill frontmatter (`name` + `description`) — DONE

Every `SKILL.md` now opens with YAML frontmatter (`name` matching the directory, a keyword-front-loaded
`description`). Without it the model can't auto-discover a skill — only explicit `/name` works — which
would defeat the description-driven discovery ADR-016/017 rely on. Applied to all four current skills
(`bug-reproduction`, `batch-operations`, `git-platform`, `update-api-documentation`).

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
| 1.0 | 2026-06-03 | Accepted — skill frontmatter + hybrid command portability (opencode/Copilot native; AGENTS.md Workflows for Gemini/Cursor/Codex) |

## Related
- ADR-005: Mandatory AskUserQuestion (clarity assessment) — `{{ASK}}` is how it's satisfied cross-agent
- ADR-016: Multi-agent harness (instructions)
- ADR-017: Harness selection, skills & hooks portability
