# Contributing to dotcontext

Thanks for contributing! dotcontext is an AI context toolkit for coding agents (Claude Code, OpenAI
Codex, opencode, Gemini CLI, GitHub Copilot, Cursor). The most common contribution — and the best place
to start — is **adding a skill**, so this guide leads with that, then covers the build, PR, and release flow.

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

Issues are welcome — they're a real contribution. Before opening one, **search existing issues** to avoid
duplicates.

**Bug reports** — open an issue and include:
- what you ran (the exact `dotcontext` command and which agent/harness),
- `dotcontext --version` and your OS / shell,
- what you expected vs. what happened (paste the output),
- minimal steps to reproduce.

`dotcontext doctor` output is often useful to paste.

**Feature requests** — describe the **use case** ("I'm trying to … so that …"), not just the solution.
For a new skill or harness, say which agent(s) it targets. Larger changes are best discussed in an issue
before you open a big PR.

---

## How the project is built

- The CLI ships as a **single bash executable**, `dotcontext`, built by concatenating the modules in
  `src/` (`core/`, `setup/`, `commands/`, `main.sh`) via `make build` (see the `Makefile`).
- **You edit `src/` and the `templates/`** — never hand-edit the bundled `dotcontext` file beyond running
  `make build`. `src/header.sh` holds the single source of truth for `VERSION`.
- **Templates** (everything under `templates/`) are what users receive. `dotcontext init`/`update` fetch
  them from the **`main` branch** at runtime, so a merged template change is live immediately. The CLI
  *binary* itself is fetched from the **latest release tag** (see [release flow](#how-deploy--release-works)).

There is no compiled language and no test framework — just bash. CI runs `bash -n` (syntax) and verifies
the committed `dotcontext` matches `make build` output.

---

## Add a skill (start here)

A **skill** is a reusable `SKILL.md` guide the agent auto-discovers and pulls in when relevant (e.g.
`bug-reproduction`, `git-platform`, `update-api-documentation`). Skills are **seed** files: created once
per project and never overwritten, so they're safe to customize downstream.

### 1. Create the skill file

```
templates/.claude/skills/<your-skill-slug>/SKILL.md
```

`<your-skill-slug>` must be kebab-case. **Start the file with YAML frontmatter** — the `description` is
what every agent uses to auto-discover the skill, so front-load the keywords/filenames a user is likely
to say:

```markdown
---
name: your-skill-slug          # kebab-case, MUST match the directory name
description: >-
  One or two sentences, keyword-front-loaded: what the skill does and when to use it.
  This drives auto-discovery on Claude, Codex, opencode, Gemini, Copilot, and Cursor.
---
# Skill: Your Skill Name

## When to Use

- [Concrete situation 1]
- [Concrete situation 2]

## Step by Step

### 1. [Step]
[Explanation + a real code example]

## Anti-Patterns

**Don't:** …
**Do:** …
```

Match the structure of the existing skills in `templates/.claude/skills/`. Keep it stack-agnostic where
possible (show one stack as an example, don't hard-code one).

> **Why the frontmatter matters:** without `name`/`description`, agents can't auto-discover the skill —
> it would only work via an explicit `/name`. The `description` is the discovery surface. (ADR-016/017/018)

### 2. Wire it into the CLI

Skills are emitted per selected harness — to `.claude/skills/` (Claude) and/or `.agents/skills/` (Codex,
opencode, Gemini, Copilot, Cursor, via a mirror). Add your skill in **two** places:

1. **`src/commands/init.sh`** — in the skills block, add the slug to the `mkdir -p "$skills_dir/…"` line
   and add a matching `download_if_missing` line.
2. **`src/commands/update.sh`** — add a line to the `seed_templates` array so existing projects receive it
   on `dotcontext update --templates`:
   ```
   "templates/.claude/skills/<your-skill-slug>/SKILL.md:.claude/skills/<your-skill-slug>/SKILL.md"
   ```

### 3. Reference it in AGENTS.md

Add a one-liner under **Additional Context** in `templates/AGENTS.md` so the canonical instructions point
at it:

```markdown
- Your skill topic → `.claude/skills/<your-skill-slug>/SKILL.md`
```

### 4. Build & verify

```bash
make build                 # regenerate the dotcontext binary
bash -n dotcontext         # syntax check
git diff --quiet dotcontext && echo "in sync"   # must be in sync (CI enforces this)
```

Commit **both** your `src/`/`templates/` changes **and** the rebuilt `dotcontext`.

---

## Other contributions

- **A workflow command** (e.g. a new `/something`): add `templates/.claude/commands/<name>.md`, then add
  the name to `DOTCONTEXT_COMMANDS` in `src/setup/agents.sh` and to the Claude command loop in
  `src/commands/init.sh`. Use a neutral "ask the user with your structured-question tool" phrasing for
  clarifications so it ports across agents. Document it in the `## Workflows` table in `templates/AGENTS.md`.
- **A new agent/harness**: add one entry to the registry in `src/setup/agents.sh` (`AGENT_IDS`,
  `agent_name`, `agent_detect`, `agent_instructions_file`, `agent_emit_mode`) plus its hook/command
  emission. See ADR-016/017/018 for the model.
- **An architectural decision**: add an ADR under `.context/decisions/` following the house format
  (see existing ADRs and `.context/decisions/README.md`).

---

## Local development

```bash
make build            # bundle src/ → ./dotcontext
./dotcontext --help   # run your local build
./dotcontext doctor   # exercise a command
bash -n dotcontext    # syntax check (matches CI)
```

Keep it **POSIX / Bash 3.2 compatible** (macOS ships 3.2 — no associative arrays, etc.). Test on macOS and
Linux where you can.

---

## Pull request workflow

1. **Branch** from `main`: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
2. **Commit** using conventional-commit style (`feat:`, `fix:`, `docs:`, `chore:`) — it shapes the release
   notes. Always commit the rebuilt `dotcontext` alongside `src/` changes.
3. **Open the PR** against `main`. CI (`​.github/workflows/ci.yml`) runs `bash -n` on every module + the
   binary, and fails if `dotcontext` is out of sync with `src/`. CodeRabbit posts an automated review.
4. Address review comments; keep the branch green.

---

## Decision compliance (ADRs)

Before a change that alters behavior, check `.context/decisions/` for a related ADR. If your change
conflicts with one, **say so in the PR** and either comply, or supersede the ADR with a new version
(reference the old one). New significant decisions get their own ADR.

---

## How deploy / release works

This is the part contributors most often get wrong, so read it carefully.

**Merging a PR does _not_ create a release.** Merging to `main`:
- makes **template changes live immediately** — `dotcontext init` / `dotcontext update --templates` pull
  templates from `main`, so a merged skill is available right away to anyone re-running those;
- does **not** update the CLI **binary** users download — that comes from the latest **release tag**. So a
  change to `src/` (init/update wiring, doctor, etc.) only reaches users after a release.

**A release is a separate, explicit step** (automated via `.github/workflows/release.yml`, ADR-014):

1. Bump the version in **`src/header.sh`** (never the built binary), then `make build`.
2. Update `CHANGELOG.md`.
3. Commit (`chore(release): vX.Y.Z`) and create the tag `vX.Y.Z`.
4. `git push && git push --tags`.
5. Pushing the `v*` tag triggers `release.yml`, which verifies the binary is in sync, checks the tag
   matches `VERSION`, generates notes from `git log`, and publishes the GitHub release. **Do not run
   `gh release create` by hand.**

Maintainers can run the `/release [patch|minor|major]` workflow in Claude Code to do steps 1–4.

So for a skill (or any `src/`-touching change) to fully reach users: **merge, then cut a release.**
Pure template-only additions are live on merge, but a release is still recommended so the CLI's seed list
(which references the new file) ships in the binary too.

---

## Community expectations

Be respectful, constructive, and patient — assume good intent. Keep discussion focused on the work, give
actionable feedback, and welcome newcomers (everyone's first PR is a learning curve). Harassment or
disrespectful behavior isn't tolerated. If the project adds a `CODE_OF_CONDUCT.md`, it governs all project
spaces; until then, these expectations apply.

### Resources

- **README** — overview, install, and command reference.
- **`.context/CONTEXT.md`** — domain and architecture.
- **`.context/decisions/`** — architectural decisions (ADRs), including the multi-agent design (016–018).

Questions? Open an issue. Thanks for making dotcontext better.
