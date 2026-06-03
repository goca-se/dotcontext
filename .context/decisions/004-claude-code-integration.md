# ADR-004: Claude Code Integration via Slash Commands

**Status:** Accepted (extended beyond Claude by ADR-016/017/018)
**Date:** 2025-01-31
**Version:** 1.0
**Deciders:** Gocase Team

> **Note (2026-06):** the "tightly coupled to Claude Code (won't work with other AI tools)" tradeoff below
> has been lifted — dotcontext now serves six harnesses. Instructions go through a canonical `AGENTS.md`
> (ADR-016), skills/hooks port per agent (ADR-017), and workflows reach each agent's command primitive or
> the `AGENTS.md` Workflows section (ADR-018). This ADR is kept as the original Claude-first record.

## Context

dotcontext creates documentation structure, but the real value comes from AI assistants using that documentation. We needed to decide how to integrate with Claude Code (Anthropic's CLI for Claude).

## Decision

Create markdown files in `.claude/commands/` that Claude Code automatically loads as slash commands. These commands contain prompts that instruct Claude how to analyze codebases, generate PRPs, and execute implementations.

Commands created:
- `/setup-context` - Analyze codebase and populate context files
- `/generate-prp` - Plan a feature with user questions
- `/execute-prp` - Implement a planned feature
- `/code-review` - Structured code review
- `/add-*` - Interactive helpers for adding context

## Alternatives Considered

1. **MCP Server** - Would require separate process, more complex setup
2. **VS Code extension** - Limits to one editor, not CLI-compatible
3. **Standalone prompts** - Users would have to copy/paste manually
4. **API integration** - Would require API keys, network calls

## Consequences

### Positive
- Zero configuration for users (commands just work after init)
- Commands are project-specific (live in repo)
- Markdown is easy to read, edit, and version control
- Leverages Claude Code's built-in command system

### Negative
- Tightly coupled to Claude Code (won't work with other AI tools)
- Command syntax must follow Claude Code's expectations
- Changes to Claude Code's command system could break us

### Risks
- Claude Code command format may change
- Mitigation: Monitor Claude Code updates, version our commands

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-31 | Initial decision |

## Related
- ADR-005: AskUserQuestion requirement
- ADR-016: Multi-agent harness (extends this beyond Claude)
- ADR-017: Skills & hooks portability + harness selection
- ADR-018: Command portability & invocation modes
