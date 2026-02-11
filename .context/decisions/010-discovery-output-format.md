# ADR-010: Discovery Output Format

**Status:** Accepted
**Date:** 2026-02-10
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

The `/deep-context` command produces a discovery document containing business rules, cross-repo validations, and code references. We needed to standardize the output format for consistency, readability, and potential future tooling.

## Decision

Use **plain Markdown with tables** for discovery output documents, saved to `.context/discoveries/YYYYMMDD-[slug].md`.

### Document Structure
1. **Header** — Title, generation date, repos analyzed
2. **Executive Summary** — 3-5 bullet points of key findings
3. **Business Rules Discovered** — Categorized tables with file:line references and confidence scores
4. **Cross-Repo Validation** — Matches, contradictions, and gaps between repos
5. **References** — All files analyzed
6. **Metadata** — Query, repos, agent count, cache status

### Key Format Rules
- Every finding must include `file:line` reference (no fabricated data)
- Confidence scores expressed as percentages
- Findings below 50% confidence are auto-removed by Agent 5
- Tables used for structured data; prose for detailed explanations
- Code snippets included in "Details" subsections

### File Naming
- Pattern: `YYYYMMDD-[query-slug].md`
- Example: `20260210-checkout-flow.md`
- Never overwrite existing files; append `-2`, `-3` if duplicate date+slug

## Alternatives Considered

1. **YAML frontmatter + Markdown** — Structured metadata header with markdown body. Rejected: adds parsing complexity, YAML not always human-friendly for large documents.
2. **JSON output** — Machine-readable structured data. Rejected: not human-readable, harder to review and edit.
3. **HTML report** — Rich formatting with styling. Rejected: not version-control friendly, harder to diff.

## Consequences

### Positive
- Human-readable without special tools
- Version control friendly (easy to diff)
- Consistent with existing `.context/` documentation format
- Can be referenced by `--cache` flag in future runs

### Negative
- Less structured than JSON for programmatic access
- Tables can be wide and hard to read in narrow terminals

### Risks
- Format may need extending for future multi-repo (3+) support
- Mitigation: Sections are modular; new sections can be added without breaking existing ones

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-10 | Initial decision |

## Related
- ADR-009: Multi-Agent Orchestration Pattern
- ADR-004: Claude Code Integration via Slash Commands
