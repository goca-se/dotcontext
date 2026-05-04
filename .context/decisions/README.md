# Architectural Decision Records (ADRs)

Record of significant technical decisions in this project.

## Index

| ADR | Title | Status | Schema |
|-----|-------|--------|--------|
| [001](001-single-bash-executable.md) | Single Bash Executable Architecture | Accepted | 1.0 |
| [002](002-template-download-strategy.md) | Template Download Strategy | Accepted | 1.0 |
| [003](003-safe-update-behavior.md) | Safe Update Behavior | Accepted | 1.0 |
| [004](004-claude-code-integration.md) | Claude Code Integration via Slash Commands | Accepted | 1.0 |
| [005](005-askuserquestion-requirement.md) | Mandatory AskUserQuestion Tool Usage | Accepted | 1.0 |
| [006](006-auto-setup-on-init.md) | Auto-run /setup-context on Init | Accepted | 1.0 |
| [007](007-cli-simplification.md) | CLI Simplification - Remove Add Commands | Accepted | 1.0 |
| [008](008-remove-examples-directory.md) | Remove examples/ Directory | Accepted | 1.0 |
| [009](009-multi-agent-orchestration-pattern.md) | Multi-Agent Orchestration Pattern | Accepted | 1.0 |
| [010](010-discovery-output-format.md) | Discovery Output Format | Accepted | 1.0 |
| [011](011-test-driven-bug-fixing-pattern.md) | Test-Driven Bug Fixing Pattern | Accepted | 1.0 |
| [012](012-agent-file-extraction-pattern.md) | Agent File Extraction Pattern | Accepted | 1.0 |
| [013](013-structured-exploration-pattern.md) | Structured Exploration Pattern | Accepted | 1.0 |
| [014](014-marketplace-tui-architecture.md) | Marketplace TUI Architecture | Accepted | 2.0 |
| [015](015-two-layer-distribution-model.md) | Two-Layer Distribution Model | Accepted | 2.0 |
| [016](016-lockfile-format-and-scope-resolution.md) | Lockfile Format and Scope Resolution | Accepted | 2.0 |
| [017](017-bundle-granularity.md) | Bundle Granularity (Atomic Items) | Accepted | 2.0 |
| [018](018-existing-user-migration-via-auto-registration.md) | Existing User Migration via Auto-Registration | Accepted | 2.0 |
| [019](019-adr-template-v2-coexistence.md) | ADR Template v2 (Coexistence) | Accepted | 2.0 |

## Template

ADRs in this project use **schema 2.0** going forward (ADR-019). Existing v1.0 ADRs are not migrated — coexistence is intentional.

### Schema 2.0 (use for new ADRs)

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Version:** 1.0
**Schema:** 2.0
**Deciders:** [Names]
**Stakeholders:** [Roles/teams affected — be specific, not "the team"]

## Context

[Why was this decision needed? What forces are at play?]

## Decision

[What was decided?]

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Option A | ... | ... | ... |
| Option B | ... | ... | ... |

## Trade-offs Accepted

[What are we explicitly giving up by choosing this? Name pain points we accept rather than burying them in "Consequences/Negative".]

## Validation Criteria

[How will we know this decision was right or wrong? Concrete signals: metrics, observations, time horizons.]

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Risks:** ...

## Related ADRs

- ADR-XXX: ...

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial decision |
```

### Schema 1.0 (legacy — for reference only)

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Version:** 1.0

## Context
## Decision
## Consequences
- **Positive:** ...
- **Negative:** ...
## History
```

## Conventions

- **Numbering:** Sequential, 3 digits with leading zeros (001, 002, ...)
- **Filename:** `NNN-title-in-slug.md`
- **Status:**
  - `Proposed` - Under discussion
  - `Accepted` - Approved and in use
  - `Deprecated` - Still works but not recommended
  - `Superseded` - Replaced by another ADR (link it)

## Adding Decisions

In Claude Code, use the interactive command:
```
/add-decision
```

This will ask clarifying questions and populate the ADR with context.
