# ADR-012: Agent File Extraction Pattern

**Status:** Accepted
**Date:** 2026-03-04
**Version:** 1.0
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

Agent files are **managed templates** — always downloaded during `dotcontext init` and offered for update during `dotcontext update`. They follow the same pattern as command files.

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
| 1.0 | 2026-03-04 | Initial decision |

## Related
- ADR-009: Multi-Agent Orchestration Pattern (updated to reference file-based agents)
- ADR-004: Claude Code Integration via Slash Commands
