# {{projectName}}

> [Project description - one line]

## Decision Compliance

**IMPORTANT:** Before implementing any change, check `.context/decisions/` for related ADRs.

If a requested change conflicts with an existing decision:
1. **Stop and inform the user** which ADR(s) would be affected
2. **Ask explicitly** if they want to:
   - Proceed and update the decision
   - Modify the approach to comply with existing decision
   - Cancel the change
3. **If updating a decision**, create a new version:
   - Change status to `Superseded by ADR-XXX`
   - Create new ADR with updated decision
   - Reference the previous ADR

## Stack

- [Language and version]
- [Framework]
- [Database]
- [Other major dependencies]

## Commands

**Important:** Check if this project uses Docker (docker-compose.yml, Dockerfile). If so, run commands via Docker (e.g., `docker compose exec app npm test` instead of `npm test`).

```bash
# Development
# [dev command]

# Testing
# [test command]

# Linting
# [lint command]

# Build/Deploy
# [build command]
```

## Critical Rules

1. **Always ask before assuming** - When there is ambiguity, multiple valid approaches, or decisions to be made, use the AskUserQuestion tool to clarify before proceeding. Never assume user intent.
2. **[Rule 1]** - [Why it matters]
3. **[Rule 2]** - [Why it matters]
4. **[Rule 3]** - [Why it matters]

## Architecture

### [Section 1]

[Brief description of key architectural pattern]

### [Section 2]

[Brief description of another key pattern]

---

## Additional Context

- Domain and architecture → `.context/CONTEXT.md`
- Architectural decisions → `.context/decisions/`
- Task-specific skills → `.context/skills/`
