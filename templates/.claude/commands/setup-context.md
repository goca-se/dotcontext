# Setup Context

Analyze this codebase and populate the AI context files via a guided interview.

## Operating principles

This command is an **interview, not a one-shot generator**. Walk the user through explicit phases. At each phase, infer what you can with high confidence; ask `AskUserQuestion` for what you can't.

### Confidence scoring

After analyzing each item (a stack detection, a critical rule, a domain assumption), rate your confidence:

- **High (≥80%)** — You're sure. Fill in and move on. Show the user the value at the end of the phase, not per-item.
- **Medium (50-79%)** — You have a guess. Fill in, but **show the user and confirm**: "I think the test command is `pnpm test`. Correct?"
- **Low (<50%)** — You don't have enough signal. **Ask before filling.**

This filters questions: don't pester the user about things you already know, and don't fabricate things you don't.

### Skip is a first-class option

At the start of each phase, offer:

> AskUserQuestion: "Phase N: [phase name]. How do you want to proceed?"
> Options:
> - "Continue (Recommended)" — run the phase normally
> - "Skip this phase" — leave these files as-is
> - "Show what's pending" — preview what this phase would generate before deciding

### Final review before saving

When all phases are done, show the user a **summary of every file you intend to write or modify** and let them edit it before saving:

> "I'm about to write/modify these files: [list with a 1-line summary each]. Save all? (Or: review specific files)"

---

## Phase 1: Discovery

**Goal:** understand the project at a high level — language, framework, structure, entry points.

1. Read `README.md` if it exists.
2. Detect language and framework from dependency files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `pom.xml`, `build.gradle`).
3. Check for Docker (`docker-compose.yml`, `Dockerfile`).
4. Identify main entry points (`src/main.*`, `cmd/`, `bin/`, `app.py`, etc.).
5. Glance at directory structure (max 2 levels deep).

After Phase 1, you should be able to answer: *what does this project do, in one sentence?* If you can't, raise confidence to **low** and ask.

---

## Phase 2: CLAUDE.md (project root)

**Goal:** populate `CLAUDE.md` with project name, stack, commands, critical rules, architecture summary.

For each section, score confidence and act accordingly:

| Section | Inputs | Likely confidence |
|---------|--------|-------------------|
| Project name + description | README, package name | High → fill |
| Stack | dependency files | High → fill |
| Commands (dev/test/lint/build) | `package.json` scripts, `Makefile`, README | Medium → fill + confirm |
| Critical Rules | Linting configs, README "contributing", existing patterns | **Low → ask** |
| Architecture summary | top-level dir names | Medium → fill + confirm |

**Important** — for `Commands`, if the project uses Docker, prefix commands with `docker compose exec <service>`.

For `Critical Rules`, **always** ask:

> AskUserQuestion: "What 2-3 rules must always be followed in this codebase? (Examples: 'Always use the X API, not Y.' / 'Database migrations must be reversible.' / 'No new dependencies without team review.')"

Don't fabricate critical rules. Empty is better than wrong.

---

## Phase 3: .context/CONTEXT.md

**Goal:** document the domain — what problem this solves, who uses it, core entities, modules, flows, integrations, glossary.

Reading the code can answer "modules" and "integrations" with high confidence. The user has to answer the rest:

> AskUserQuestion: "Who are the users of this system? What problem does it solve for them?"

> AskUserQuestion: "What are the 3-5 most important domain concepts (entities or terms)?"

> AskUserQuestion: "What's a critical user flow I should document? (Examples: 'login → email verification', 'checkout → payment → fulfillment'.)"

For glossary, scan source files for repeated domain-specific names that aren't framework terms — flag any that aren't obvious from context and ask the user to confirm meaning.

---

## Phase 4: Architecture section in CONTEXT.md

After Phase 3, generate an Architecture section:

1. **System Overview** (2-3 sentences). Architecture style: monolith, microservices, serverless, CLI, library, etc. — detectable with high confidence.
2. **Directory Structure** — tree view, max 2 levels, one-line description per top-level dir. High confidence from `ls`.
3. **Key Dependencies** — read dependency files; list externals grouped by category (Framework, Database, Testing, etc.) in a table. High confidence.
4. **Data Flow** — trace from entry points to data stores. Medium confidence — confirm with the user.

Skip a sub-section if not applicable (e.g., no data flow for a CLI library).

---

## Phase 5: Coding Conventions

**Goal:** detect and document coding patterns the codebase actually follows.

Adaptive sample size:
- < 20 source files → analyze 5
- 20-100 files → analyze 10
- 100+ files → analyze 20

Pick representative files (entry points, one per major module, files with tests, route handlers).

For each of these 6 categories, document only patterns that appear in **multiple files** (not one-offs):

1. **Naming Patterns** (camelCase, snake_case, PascalCase, file naming, DB columns)
2. **Error Handling** (try/catch, Result, callbacks, custom errors)
3. **Testing Style** (framework, assertion library, mocking)
4. **Import Organization** (grouping, sorting, relative vs absolute)
5. **State Management** (Redux, Context, Vuex, sessions, or N/A)
6. **API Response Format** (JSON:API, envelope, GraphQL, or N/A)

Skip categories that don't apply. Use real code excerpts when illustrating.

Confidence here is usually high if the codebase is consistent — but **always show your conclusions to the user** before writing, since you might be looking at the wrong sample.

---

## Phase 6: ADRs in .context/decisions/

**Goal:** create 3-5 ADRs documenting decisions already made.

Look for evidence of decisions:

- Choice of framework / language
- Authentication approach
- Database design patterns (relational vs document, ORMs)
- API design (REST, GraphQL, RPC)
- State management approach
- Testing strategy
- Deployment setup

For each candidate, **ask the user**:

> AskUserQuestion: "I see this project uses [decision]. Want to record this as an ADR? (You'll be asked for context and trade-offs.)"

If yes, follow `/add-decision` flow internally — but write the ADRs with **schema 2.0** (Stakeholders, Trade-offs Accepted, Validation Criteria sections).

If you can't infer any decision worth recording, skip — better to have zero ADRs than fabricated ones.

---

## Phase 7: .gitignore for generated context

Check `.gitignore`. If missing, ask:

> AskUserQuestion: "I'd like to add three entries to `.gitignore` so per-session AI files (`.context/prp/`, `.context/discoveries/`, `.context/bugs/`) don't get committed. OK?"

If yes, append:

```
# dotcontext generated files (per-session, not versioned)
.context/prp/
.context/discoveries/
.context/bugs/
```

---

## Phase 8: Final review and save

Show the user a summary of every file you intend to write or modify:

```
About to write / modify:
  - CLAUDE.md (created)
  - .context/CONTEXT.md (created)
  - .context/decisions/001-database-choice.md (created)
  - .context/decisions/002-test-framework.md (created)
  - .gitignore (3 lines appended)

Save all? (or: review a specific file)
```

If the user wants to review one, show its contents and ask for edits.

---

## Output

After saving, summarize:

```
✅ Context setup complete!

Created/Updated:
- CLAUDE.md - <one-line description>
- .context/CONTEXT.md - <one-line description>
- .context/decisions/NNN-xxx.md - <title>
- .context/decisions/NNN-yyy.md - <title>

Next steps:
  • Run `dotcontext` (no args) to install Layer 2 items (code-review, fix-bug, MCPs, etc.)
  • Refine any section by editing the file directly.
```

## If you get stuck

If you can't make progress after 3 attempts at the same step:

1. Stop immediately.
2. Explain what you're trying to do and what's blocking you.
3. **Use AskUserQuestion** to ask how to proceed.

Never loop indefinitely.
