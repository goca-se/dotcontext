# Architectural Decision Records (ADRs)

Record of significant technical decisions in this project.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [001](001-single-bash-executable.md) | Single Bash Executable Architecture | Accepted |
| [002](002-template-download-strategy.md) | Template Download Strategy | Accepted |
| [003](003-safe-update-behavior.md) | Safe Update Behavior | Accepted |
| [004](004-claude-code-integration.md) | Claude Code Integration via Slash Commands | Accepted |
| [005](005-askuserquestion-requirement.md) | Mandatory AskUserQuestion Tool Usage | Accepted |
| [006](006-auto-setup-on-init.md) | Auto-run /setup-context on Init | Accepted |
| [007](007-cli-simplification.md) | CLI Simplification - Remove Add Commands | Accepted |
| [008](008-remove-examples-directory.md) | Remove examples/ Directory | Accepted |
| [009](009-multi-agent-orchestration-pattern.md) | Multi-Agent Orchestration Pattern | Accepted |
| [010](010-discovery-output-format.md) | Discovery Output Format | Accepted |
| [011](011-test-driven-bug-fixing-pattern.md) | Test-Driven Bug Fixing Pattern | Accepted |
| [012](012-agent-file-extraction-pattern.md) | Agent File Extraction Pattern | Accepted |
| [013](013-structured-exploration-pattern.md) | Structured Exploration Pattern | Accepted |

## Template

To create a new ADR, use the template below and save as `NNN-title-slug.md`:

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Version:** 1.0

## Context

[Why was this decision needed?]

## Decision

[What was decided?]

## Consequences

- **Positive:** ...
- **Negative:** ...

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial decision |
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
