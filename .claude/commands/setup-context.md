# Setup Context

Analyze this codebase and populate the AI context files with relevant information.

## Instructions

You are setting up context documentation for AI assistants working on this codebase. Analyze the project thoroughly and fill in each file with specific, accurate information.

**Important guidelines:**
- Be specific to THIS project - avoid generic descriptions
- Use actual code examples from the codebase
- Keep content concise - too much context is counterproductive
- Preserve any content the user has already written
- **Use AskUserQuestion tool** to clarify any ambiguity before proceeding

## Tasks

### 1. Analyze the Project

First, understand:
- What language/framework is used?
- What is the project structure?
- What does this project do?
- What are the main entry points?
- **Does it use Docker?** Check for `docker-compose.yml`, `Dockerfile`, or similar. If yes, commands should be run via Docker (e.g., `docker compose exec <service> <command>`).

### 2. Fill CLAUDE.md

Update the root `CLAUDE.md` with:

- **Project name and description**: Clear one-liner explaining what this is
- **Stack**: Language version, framework, database, key dependencies
- **Commands**: Actual commands from package.json, Makefile, or scripts (dev, test, lint, build). **If Docker is used**, prefix commands with docker compose exec (e.g., `docker compose exec web rails test`)
- **Critical Rules**: Project-specific rules that must always be followed (discovered from linting configs, existing patterns, or README)
- **Architecture**: Brief overview of main patterns used

### 3. Fill .context/CONTEXT.md

Document the domain:

- **Overview**: What problem does this solve? Who uses it?
- **Core Entities**: Main models/types and their responsibilities
- **Modules/Packages**: Directory structure with brief descriptions
- **Main Flows**: Key user journeys or data flows (auth, main business logic)
- **Integrations**: External APIs, services, databases
- **Glossary**: Domain-specific terms used in the code

### 4. Generate Architecture Section in CONTEXT.md

After filling the domain sections, generate a comprehensive Architecture section in `.context/CONTEXT.md`:

1. **System Overview** — Write 2-3 sentences describing the system's purpose and architecture style (monolith, microservices, serverless, CLI, library, etc.)
2. **Directory Structure** — Create a tree-style map of top-level directories (max 2 levels deep) with one-line descriptions of each module's purpose. Use `ls` and explore the project structure.
3. **Key Dependencies** — Read dependency files (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `build.gradle`, `pom.xml`, `composer.json`, etc.) and list external libraries grouped by category (Framework, Database, Testing, etc.) in a table.
4. **Data Flow** — Describe how data moves through the system at a high level (e.g., Request → Middleware → Controller → Service → Database). Trace from entry points to data stores.

Write findings into the Architecture section of CONTEXT.md (between Modules/Packages and Conventions).

### 5. Detect Coding Conventions

Analyze source files to discover and document consistent coding patterns.

**Adaptive file sampling:**
1. Count total source files in the project (exclude `node_modules`, `vendor`, `.git`, `dist`, `build`, etc.)
2. Select sample size:
   - < 20 files → analyze 5
   - 20-100 files → analyze 10
   - 100+ files → analyze 20
3. Pick representative files from different modules/directories, prioritizing:
   - Entry points and main files
   - One file per major directory/module
   - Files with tests (to detect testing patterns)
   - API route handlers or controllers

**Analyze these 6 convention categories across the sampled files:**

1. **Naming Patterns** — Variable casing (camelCase, snake_case), class naming (PascalCase), file naming conventions, database column naming
2. **Error Handling** — try/catch, Result types, error callbacks, custom error classes, error boundaries
3. **Testing Style** — Test framework (describe/it, test(), pytest), assertion library, mocking approach, test file naming
4. **Import Organization** — Grouping (stdlib, external, internal), sorting, relative vs absolute paths
5. **State Management** — Redux, Context, Vuex, MobX, server-side sessions, or N/A
6. **API Response Format** — JSON:API, envelope pattern, GraphQL, or N/A

**Important rules:**
- Only document patterns that appear **consistently across multiple files** (not one-offs)
- Skip categories that don't apply to this project (e.g., State Management for a CLI tool)
- Use actual code examples from the codebase when illustrating patterns

Write findings into the Conventions section of CONTEXT.md (after Architecture).

### 6. Create ADRs in .context/decisions/

Identify 3-5 significant architectural decisions already made:

Look for:
- Choice of framework/language
- Authentication approach
- Database design patterns
- API design (REST, GraphQL, etc)
- State management approach
- Testing strategy
- Deployment setup

For each, create an ADR file following the template in `.context/decisions/README.md`

### 7. Create Skills in .claude/skills/

Identify 2-3 recurring patterns that would benefit from documentation:

Look for:
- How to add a new feature/endpoint/component
- Testing patterns specific to this project
- Common operations (migrations, deployments, etc)

For each, create a skill folder with SKILL.md following the template.

### 8. Populate Bug Reproduction Skill

If `.claude/skills/bug-reproduction/SKILL.md` exists (created by `dotcontext init`), fill in the project-specific sections:

- **Test Framework**: Detect from `package.json` (jest, vitest, mocha), `Gemfile` (rspec, minitest), `pyproject.toml`/`setup.py` (pytest, unittest), `go.mod` (go test), etc.
- **Run command**: The actual command to run tests (from `CLAUDE.md` or project config)
- **Test directory**: Where tests live in this project
- **E2E Framework**: Detect Cypress, Playwright, Selenium if present
- **Examples**: Find 1-2 real test examples from the codebase that demonstrate the project's test patterns

### 9. Verify MCP Server Configuration

Check if `.mcp.json` exists in the project root. If it does:
- Verify the configured servers make sense for this project
- Report which MCP servers are configured

If `.mcp.json` does NOT exist, ask the user if they'd like to configure MCP servers:
- **Context7** (`@upstash/context7-mcp`) — provides up-to-date library documentation for LLMs
- **Atlassian** (`https://mcp.atlassian.com/v1/sse`) — Jira + Confluence access via OAuth

If the user wants MCPs, create `.mcp.json` with the selected servers:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/sse"
    }
  }
}
```

Only include the servers the user selected.

### 10. Configure StatusLine

Check if `.claude/settings.json` exists in the project root. If it does, check if it already has a `statusLine` configuration.

If no StatusLine is configured, **use AskUserQuestion**:
> "Would you like to enable the StatusLine? It shows git branch, changes count, context health, and model info at the bottom of Claude Code."
> Options: "Yes, enable StatusLine" (Recommended) | "No, skip StatusLine"

If the user wants StatusLine:

1. Verify `.claude/scripts/statusline.sh` exists (created by `dotcontext init`). If missing, inform the user to run `dotcontext update`.

2. Create or merge `.claude/settings.json` with:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash .claude/scripts/statusline.sh"
  }
}
```

If `.claude/settings.json` already exists with other settings, merge the `statusLine` key without overwriting existing keys.

3. Ensure the script is executable:
```bash
chmod +x .claude/scripts/statusline.sh
```

### 11. Ensure .gitignore excludes generated context

Check if `.gitignore` exists. If it does, verify it includes these entries. If any are missing, add them:

```
# dotcontext generated files (per-session, not versioned)
.context/prp/
.context/discoveries/
.context/bugs/
```

These directories contain generated content that is session-specific and should not be committed.

## Output

After completing each file, summarize what you created:

```
✅ Context setup complete!

Created/Updated:
- CLAUDE.md - [brief description of what was added]
- .context/CONTEXT.md - [brief description]
- .context/decisions/001-xxx.md - [title]
- .context/decisions/002-xxx.md - [title]
- .claude/skills/xxx/SKILL.md - [title]
```

Ask the user to review and refine any sections that need their input.

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
