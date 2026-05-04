# ADR-015: Two-Layer Distribution Model

**Status:** Accepted
**Date:** 2026-04-30
**Version:** 3.0
**Schema:** 2.0
**Deciders:** Nicholas (Gocase)
**Stakeholders:** new users running `dotcontext init`, existing users on previous versions, dotcontext maintainers

## Context

dotcontext init has historically created **everything**: 12 slash commands, 12 agents, 3 skills, statusline, notification hooks, and MCP setup prompts. Two problems followed:

1. **Forced content the user may not want.** A GitLab user receives `/create-pr` with GitHub-flavored conventions. A solo developer receives multi-agent code-review they will never run.
2. **Acoplamento da metodologia com features opcionais.** `.context/` (the methodology — ADRs, skills, CONTEXT.md) shipped together with productivity helpers. Users could not adopt the methodology without also accepting the helpers.

We need a clear separation between "the methodology" (mandatory for dotcontext to work) and "productivity items" (opt-in).

## Decision

Split distributable content into **two layers**:

### Layer 1 (mandatory — installed by `dotcontext init`)

The absolute minimum to bootstrap the methodology — and nothing else.

| Item | Reason |
|------|--------|
| `.context/` skeleton (CONTEXT.md, decisions/, prp/, etc.) | The methodology surface itself |
| `CLAUDE.md` | Decision compliance instructions |
| `.claudeignore` | Sensible defaults for what Claude should not read |
| `/setup-context` | The single command that bootstraps `.context/` from the codebase |

That's it. No agents, no other commands, no skills, no scripts.

### Layer 2 (opt-in — installed via TUI)

**Everything else.** All commands besides `/setup-context`, all agents, all skills, all MCPs, all external CLIs, all hooks, all scripts.

This includes items that previous versions of this ADR (v1, v2) treated as Layer 1 — `/add-decision`, `/add-skill`, `/add-command`, `/commit`, `/deep-context` and its 4 agents. They were Layer 1 under the looser "universally desired" criterion; v3.0 drops that criterion.

### Decision rule (v3.0 — strict)

> **Layer 1 = pastas + templates + `/setup-context`.** Anything that creates, populates, or consumes `.context/` beyond the initial bootstrap is Layer 2. **No exceptions.**

Binary test for any candidate: *"Is this required for `dotcontext init && claude '/setup-context'` to function?"* If no, it's Layer 2.

### Why the strict rule

The "universally desired" escape hatch in v1/v2 turned out to be unprincipled. `/commit` is "universal" — but so is `/code-review` for many teams. Once "universal" is admissible, every item argues it deserves Layer 1 status. The boundary creeps and the marketplace's purpose blurs ("if init brings most things, what's the marketplace for?"). The strict rule has a single non-negotiable test, no judgment calls.

### Where the marketplace sits in the user journey

After `init`, the user has the methodology and `/setup-context`. The init output explicitly directs them to run `dotcontext` (no-args) in a regular terminal to open the marketplace TUI, where pressing **P** marks all 16 starter pack items (which now include `/add-decision`, `/add-skill`, `/add-command`, `/commit`, `/deep-context`, `/code-review`, `/fix-bug`, `/create-pr`, `/pr-comment`, `/generate-prp`, `/execute-prp`, plus 3 MCPs and 2 external CLIs) for one-keystroke install.

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Single layer (status quo) | No mental model to learn | Forces unwanted content; couples methodology with helpers | The original problem |
| Single layer + `--minimal` flag | Tiny code change | Still all-or-nothing; flag is hidden | Doesn't enable per-item choice |
| Three layers (Core / Recommended / Optional) | Finer granularity | Where does each item belong? Bikeshedding; Recommended creeps to Mandatory | Over-engineered |
| Two layers (chosen) | Clear binary; easy to explain | Still requires choosing the boundary per item | Best balance of clarity vs. flexibility |

## Trade-offs Accepted

- **Two-step onboarding is the new default.** Users who want any productivity helper (including `/commit`) must run `dotcontext init` *then* `dotcontext` and press P + I. The post-init message guides this transition. Friction is real (one extra command); the conceptual win (clean Layer 1 / Layer 2 boundary) is judged worth it.
- **Distribution code grows.** Layer 2 needs a manifest, lockfile, scope resolver, and per-type installers. We accept this cost in exchange for opt-in.
- **Some items now require explicit re-install on a fresh project.** Pre-v3, `/commit` and `/deep-context` came for free; now they need to be picked from the marketplace. The starter pack mitigates by putting them one keystroke away.
- **Strict rule means no judgment calls — even when judgment would help.** A future "obviously universal" item (e.g., a `/diagnose` command that helps debug dotcontext itself) cannot be Layer 1 under v3 unless it's required to bootstrap the methodology. We accept this rigidity to avoid the boundary creep that motivated v3.

## Validation Criteria

- A user running `dotcontext init` in an empty repo gets a working `.context/` setup *with no Layer 2 files in `.claude/`*.
- A user who never opens the TUI can still use the methodology end-to-end.
- A user who selects the starter pack ends up with the same files that previous `dotcontext init` produced.
- Six months in, fewer than 10% of new users complain that "X is missing" referring to a Layer 2 item — meaning the starter pack covers the common case.

## Consequences

- **Positive:** new users get a focused starting point; users who only want the methodology aren't drowned in extras; maintainers can add Layer 2 items without bloating init.
- **Negative:** anyone wanting the old all-in-one experience needs an extra step (TUI starter pack); the layer boundary has to be decided per item.
- **Risks:** boundary creep — over time Layer 1 grows because "this is universal too." Mitigated by the decision rule above and ADR review.

## Related ADRs

- ADR-002: Template Download Strategy (manifest+lockfile is the new download mechanism for Layer 2)
- ADR-007: CLI Simplification (Layer 1 minimalism aligns with CLI minimalism)
- ADR-012: Agent File Extraction Pattern (agents now bundle with their Layer 2 command, not "always downloaded")
- ADR-017: Bundle Granularity (Layer 2 items are atomic bundles)
- ADR-018: Existing User Migration via Auto-Registration (existing users keep their Layer 2 files via auto-registration)

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-30 | Initial decision |
| 3.0 | 2026-05-01 | Strict rule: Layer 1 = skeleton + `/setup-context` only. `/add-decision`, `/add-skill`, `/add-command`, `/commit`, `/deep-context` (+ 4 agents) move to Layer 2 (still in starter pack). Closes the "universally desired" loophole that diluted the marketplace's purpose. v2 was never released — went directly from v1 to v3 in the same PRP. |
