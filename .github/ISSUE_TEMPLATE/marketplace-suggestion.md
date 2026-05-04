---
name: Marketplace suggestion
about: Suggest adding a command, skill, MCP, external CLI, hook, or script to the marketplace
title: "[marketplace] "
labels: marketplace
---

## Item type

<!-- Check one. -->

- [ ] `command-bundle` (a `/slash-command` plus any agents/skills it needs)
- [ ] `skill` (a `.claude/skills/<name>/SKILL.md` guide)
- [ ] `mcp` (a Model Context Protocol server)
- [ ] `external-cli` (a binary like `gh`, `glab`, installed via OS package manager)
- [ ] `hook` (a Claude Code event hook)
- [ ] `script` (a standalone script under `.claude/scripts/`)

## Proposed id and name

<!-- id: kebab-case, unique. name: human-readable. -->

- **id:** `your-item-id`
- **name:** Your Item Name

## What it does

<!-- One paragraph. What problem does this solve for users? When would they install it? -->

## Starter pack candidate?

- [ ] Yes — most users would want this on day one
- [ ] No — useful but specialized

<!-- Be conservative with starter pack. The current 11 are intentionally minimal. -->

## Default scope

- [ ] `local` (per-project under `<repo>/.claude/`)
- [ ] `global` (per-user under `~/.claude/`)
- [ ] `machine` (system-wide; only for `external-cli`)

## Dependencies

<!-- Does this depend on other marketplace items? List their ids.
     E.g., a /create-pr command depends on the git-platform-skill. -->

## For MCP / external-cli only

<!-- MCP: paste the proposed mcp_config (type, url or command+args, auth_required). -->
<!-- CLI: paste package_managers per OS (brew/apt/dnf/pacman/winget) and verify_command. -->

```json
```

## Are you willing to send the PR?

- [ ] Yes
- [ ] I can help test / review
- [ ] No, just suggesting

<!-- See CONTRIBUTING.md "Add a marketplace item" for the full PR recipe. -->
