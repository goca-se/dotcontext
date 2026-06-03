# Contributing to dotcontext

Thanks for contributing. dotcontext is an AI context toolkit for coding agents (Claude Code, OpenAI
Codex, opencode, Gemini CLI, GitHub Copilot, Cursor). Most people contribute by adding a skill, so that's
where this guide starts. Build, PR, and release come after.

## Table of contents

- [Reporting bugs & requesting features](#reporting-bugs--requesting-features)
- [How the project is built](#how-the-project-is-built)
- [Add a skill (start here)](#add-a-skill-start-here)
- [Other contributions](#other-contributions)
- [Local development](#local-development)
- [Pull request workflow](#pull-request-workflow)
- [Decision compliance (ADRs)](#decision-compliance-adrs)
- [How deploy / release works](#how-deploy--release-works)
- [Community expectations](#community-expectations)

---

## Reporting bugs & requesting features

Issues are welcome. Before opening one, search the existing issues so you don't file a duplicate.

**Bug reports.** Open an issue and include:
- what you ran (the exact `dotcontext` command, and which agent/harness),
- `dotcontext --version`, plus your OS and shell,
- what you expected, and what happened instead (paste the output),
- the steps to reproduce it.

Pasting `dotcontext doctor` output usually helps too.

**Feature requests.** Describe the use case ("I'm trying to X so that Y"), not just the solution you have
in mind. If it's a new skill or harness, say which agent(s) it targets. For anything large, open an issue
to talk it through before you write a big PR.

---

## How the project is built

- The CLI ships as a single bash executable, `dotcontext`, built by concatenating the modules in `src/`
  (`core/`, `setup/`, `commands/`, `main.sh`) with `make build` (see the `Makefile`).
- You edit `src/` and `templates/`. Don't hand-edit the bundled `dotcontext` file; run `make build`
  instead. `src/header.sh` is the single source of truth for `VERSION`.
- The `templates/` directory is what users receive. `dotcontext init` and `dotcontext update` fetch
  templates from the `main` branch at runtime, so a merged template change is live right away. The CLI
  binary itself comes from the latest release tag (see [release flow](#how-deploy--release-works)).

There's no compiled language and no test framework, just bash. CI runs `bash -n` for syntax and checks
that the committed `dotcontext` matches the `make build` output.

---

## Add a skill (start here)

A skill is a reusable `SKILL.md` guide the agent discovers and pulls in when it's relevant (for example
`bug-reproduction`, `git-platform`, `update-api-documentation`). Skills are seed files: created once per
project and never overwritten, so they're safe to customize downstream.

### 1. Create the skill file

```
templates/.claude/skills/<your-skill-slug>/SKILL.md
```

`<your-skill-slug>` must be kebab-case. Start the file with YAML frontmatter. The `description` is what
every agent reads to decide whether to use the skill, so put the keywords and filenames a user is likely
to say up front:

```markdown
---
name: your-skill-slug          # kebab-case, MUST match the directory name
description: >-
  One or two sentences, keywords up front: what the skill does and when to use it.
  This is what drives discovery on Claude, Codex, opencode, Gemini, Copilot, and Cursor.
---
# Skill: Your Skill Name

## When to Use

- [Concrete situation 1]
- [Concrete situation 2]

## Step by Step

### 1. [Step]
[Explanation + a real code example]

## Anti-Patterns

**Don't:** ...
**Do:** ...
```

Follow the structure of the existing skills in `templates/.claude/skills/`. Keep it stack-agnostic when
you can: show one stack as an example rather than hard-coding it.

> Without `name`/`description`, agents can't discover the skill on their own; it only works if the user
> types `/name`. The `description` is the discovery surface. (ADR-016/017/018)

### 2. Wire it into the CLI

Skills are emitted per selected harness: into `.claude/skills/` for Claude, and/or `.agents/skills/` for
the others (Codex, opencode, Gemini, Copilot, Cursor), via a mirror. Add your skill in two places:

1. `src/commands/init.sh`: in the skills block, add the slug to the `mkdir -p "$skills_dir/…"` line and
   add a matching `download_if_missing` line.
2. `src/commands/update.sh`: add a line to the `seed_templates` array so existing projects pick it up on
   `dotcontext update --templates`:
   ```
   "templates/.claude/skills/<your-skill-slug>/SKILL.md:.claude/skills/<your-skill-slug>/SKILL.md"
   ```

### 3. Reference it in AGENTS.md

Add a line under Additional Context in `templates/AGENTS.md` so the canonical instructions point at it:

```markdown
- Your skill topic → `.claude/skills/<your-skill-slug>/SKILL.md`
```

### 4. Build and verify

```bash
make build                 # regenerate the dotcontext binary
bash -n dotcontext         # syntax check
git diff --quiet dotcontext && echo "in sync"   # CI fails if it isn't
```

Commit your `src/`/`templates/` changes together with the rebuilt `dotcontext`.

---

## Other contributions

- **A workflow command** (a new `/something`): add `templates/.claude/commands/<name>.md`, then add the
  name to `DOTCONTEXT_COMMANDS` in `src/setup/agents.sh` and to the Claude command loop in
  `src/commands/init.sh`. For clarifications, say "ask the user with your structured-question tool" rather
  than naming Claude's tool, so it works on every agent. List it in the Workflows table in
  `templates/AGENTS.md`.
- **A new agent/harness**: add one entry to the registry in `src/setup/agents.sh` (`AGENT_IDS`,
  `agent_name`, `agent_detect`, `agent_instructions_file`, `agent_emit_mode`), plus its hook and command
  emission. ADR-016/017/018 describe the model.
- **An architectural decision**: add an ADR under `.context/decisions/` in the house format (look at the
  existing ADRs and `.context/decisions/README.md`).

---

## Local development

```bash
make build            # bundle src/ → ./dotcontext
./dotcontext --help   # run your local build
./dotcontext doctor   # exercise a command
bash -n dotcontext    # syntax check (same as CI)
```

Keep it POSIX / Bash 3.2 compatible. macOS still ships 3.2, so no associative arrays and similar newer
features. Test on macOS and Linux where you can.

---

## Pull request workflow

1. Branch from `main` (`feat/…`, `fix/…`, `docs/…`, `chore/…`).
2. Use conventional-commit prefixes (`feat:`, `fix:`, `docs:`, `chore:`); they shape the release notes.
   Commit the rebuilt `dotcontext` whenever you change `src/`.
3. Open the PR against `main`. CI (`.github/workflows/ci.yml`) runs `bash -n` on every module and the
   binary, and fails if `dotcontext` is out of sync with `src/`. CodeRabbit posts an automated review.
4. Address the review and keep the branch green.

---

## Decision compliance (ADRs)

Before you change how something behaves, check `.context/decisions/` for a related ADR. If your change
conflicts with one, say so in the PR, then either comply with it or supersede it with a new version that
references the old one. New significant decisions get their own ADR.

---

## How deploy / release works

This trips people up, so it's worth being precise.

Merging a PR does not create a release. Merging to `main` does two things:

- Template changes go live immediately. `dotcontext init` and `dotcontext update --templates` read
  templates from `main`, so a merged skill is available to anyone who re-runs them.
- The CLI binary users download does not change. That comes from the latest release tag, so a change to
  `src/` (init/update wiring, doctor, and so on) only reaches users after a release.

A release is a separate step, automated by `.github/workflows/release.yml` (ADR-014):

1. Bump `VERSION` in `src/header.sh` (not the built binary), then `make build`.
2. Update `CHANGELOG.md`.
3. Commit (`chore(release): vX.Y.Z`) and tag `vX.Y.Z`.
4. `git push && git push --tags`.
5. Pushing the `v*` tag triggers `release.yml`. It checks the binary is in sync and the tag matches
   `VERSION`, takes the release notes from the matching `CHANGELOG.md` section (so write a good one),
   and publishes the GitHub release. Don't run `gh release create` yourself.

Maintainers can run `/release [patch|minor|major]` in Claude Code for steps 1 through 4.

So for a skill, or any change that touches `src/`, to fully reach users: merge, then cut a release. A
template-only addition is live on merge, but it's still worth releasing so the CLI's seed list, which now
references the new file, ships in the binary too.

---

## Community expectations

Be respectful and patient, and assume good intent. Keep feedback actionable and about the work. Everyone's
first PR has a learning curve, so help newcomers out. Harassment or disrespectful behavior isn't tolerated.
If the project later adds a `CODE_OF_CONDUCT.md`, it governs all project spaces; until then, this applies.

### Resources

- **README**: overview, install, and command reference.
- **`.context/CONTEXT.md`**: domain and architecture.
- **`.context/decisions/`**: the ADRs, including the multi-agent design in 016 through 018.

Questions? Open an issue.
