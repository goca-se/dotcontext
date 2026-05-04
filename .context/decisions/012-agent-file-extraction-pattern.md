# ADR-012: Agent File Extraction Pattern

**Status:** Accepted
**Date:** 2026-03-04
**Version:** 2.0
**Deciders:** Nicholas (Gocase)

## Context

Multi-agent commands (`/code-review`, `/deep-context`, `/fix-bug`) embedded all agent prompts inline within the command markdown files. This led to:

- ~10+ agent definitions duplicated across 3 command files
- Command files exceeding 300-500 lines, hard to maintain
- No way to test or reuse individual agent prompts across commands
- Difficult to iterate on agent behavior without touching command orchestration logic

## Decision

Extract all agent prompts into individual `.claude/agents/{command}/{agent-name}.md` files. Commands reference agents via `Read .claude/agents/...` at runtime instead of embedding prompts inline.

### File Structure

```
.claude/agents/
├── code-review/
│   ├── compliance-checker.md
│   ├── bug-detector.md
│   └── security-analyst.md
├── deep-context/
│   ├── step1-overview.md
│   ├── step2-subsystems.md
│   ├── step3-drill.md
│   └── step4-dataflow.md
└── fix-bug/
    ├── investigator.md
    ├── fix-conservative.md
    ├── fix-minimal.md
    ├── fix-refactor.md
    └── reviewer.md
```

### How Commands Reference Agents

Commands contain instructions like:
> Read `.claude/agents/fix-bug/investigator.md` for the agent prompt. Substitute `{bug_context}`, `{stack}`, etc. with actual values.

The orchestrator (Claude) reads the agent file, performs placeholder substitution, and passes the result to the Task tool.

### Distribution

**v1.0:** Agent files were managed templates — always downloaded during `dotcontext init`.

**v2.0 (current):** Agent files travel **with their command bundle** as one atomic unit (ADR-017). Only the deep-context agents — which belong to a Layer 1 command (`/deep-context`) — are still downloaded by `init`. Agents for Layer 2 commands (`code-review`, `fix-bug`, etc.) are downloaded *only* when the user installs that command bundle from the marketplace. Removing the bundle removes its agents.

This change keeps the file-extraction pattern (each agent is its own file, easy to read and iterate on) while honoring the layered distribution model: Layer 1 ships everything its commands need; Layer 2 items are self-contained bundles.

## Alternatives Considered

1. **Keep prompts inline** — Status quo. Rejected: maintenance burden grows with each new agent or command.
2. **Template variable system** — Build a `{{include}}` preprocessor. Rejected: over-engineered for markdown-based commands; adds build step.
3. **Agent registry/manifest** — JSON file listing agents with metadata. Rejected: premature; file structure is sufficient for discovery.

## Consequences

### Positive
- Each agent is independently readable, testable, and iterable
- Command files focus on orchestration logic, not prompt engineering
- Easy to add new agents or reuse existing ones across commands
- Cleaner diffs when modifying agent behavior

### Negative
- Additional Read tool call per agent at runtime (negligible latency for small .md files)
- More files in `.claude/agents/` directory (12 files across 3 subdirectories)
- Commands must document which placeholders to substitute

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-04 | Initial decision (extract agents to per-file under `.claude/agents/`) |
| 2.0 | 2026-04-30 | Layer 2 agents bundle with their command (atomic install/remove) instead of being always-downloaded; only Layer 1 agents (deep-context) ship via init (PRP: marketplace-tui-and-layered-distribution) |

## Related
- ADR-009: Multi-Agent Orchestration Pattern (updated to reference file-based agents)
- ADR-004: Claude Code Integration via Slash Commands
- ADR-015: Two-Layer Distribution Model
- ADR-017: Bundle Granularity (Atomic Items)
