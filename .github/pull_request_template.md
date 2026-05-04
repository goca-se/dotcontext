<!--
Thanks for contributing! Fill in the sections below honestly.
"None" / "N/A" are valid answers — empty fields aren't.
-->

## Type

<!-- Check all that apply. -->

- [ ] Bug fix
- [ ] New feature (harness / CLI)
- [ ] New marketplace item (command, skill, MCP, CLI, hook, script)
- [ ] Documentation / templates / prose
- [ ] Refactor (no behavior change)
- [ ] Chore (build, deps, tooling)

## Why

<!-- What problem does this solve, or what motivated the change?
     If this is responding to an issue, link it: "Fixes #123" / "Closes #456". -->

## Changes

<!-- Bullet list of what changed. Focus on outcome, not file-by-file diff. -->

-
-
-

## How to test

<!-- Concrete steps a reviewer can run.
     If automated tests cover it, list them.
     If manual, give the recipe (sandbox setup, expected output). -->

```bash
make check
# ...
```

## ADRs affected

<!-- One of:
     - "None" — purely tactical change
     - "Updated ADR-NNN: <reason>" — bumped version + History entry in this PR
     - "New ADR-NNN: <title>" — created in this PR
     - "Conflicts with ADR-NNN: <reason and resolution>" -->

## Final checklist

- [ ] `make build && make check` passes locally
- [ ] Relevant smoke tests pass (`tests/marketplace/smoke.sh`, `tests/marketplace/migrate_smoke.sh`, etc.)
- [ ] If marketplace item added: install + uninstall verified in `tests/sandbox.sh`
- [ ] If slash command edited: tested in a real Claude Code session
- [ ] If ADR affected: updated/created in this PR (not a follow-up)
- [ ] Bash 3.2 compatibility holds for `src/` changes
- [ ] No debug prints, commented-out code, or unexplained TODOs
