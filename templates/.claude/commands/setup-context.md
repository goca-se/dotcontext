# Setup Context

Analyze this codebase and populate the AI context files with relevant information.

## Instructions

You are setting up context documentation for AI assistants working on this codebase. Analyze the project thoroughly and fill in each file with specific, accurate information.

**Important guidelines:**
- Be specific to THIS project - avoid generic descriptions
- Use actual code examples from the codebase
- Keep content concise - too much context is counterproductive
- Preserve any content the user has already written
- Ask clarifying questions if the project's purpose is unclear

## Tasks

### 1. Analyze the Project

First, understand:
- What language/framework is used?
- What is the project structure?
- What does this project do?
- What are the main entry points?

### 2. Fill CLAUDE.md

Update the root `CLAUDE.md` with:

- **Project name and description**: Clear one-liner explaining what this is
- **Stack**: Language version, framework, database, key dependencies
- **Commands**: Actual commands from package.json, Makefile, or scripts (dev, test, lint, build)
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

### 4. Create ADRs in .context/decisions/

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

### 5. Create Skills in .context/skills/

Identify 2-3 recurring patterns that would benefit from documentation:

Look for:
- How to add a new feature/endpoint/component
- Testing patterns specific to this project
- Common operations (migrations, deployments, etc)

For each, create a skill folder with SKILL.md following the template.

### 6. Add Examples in .context/examples/

If helpful, add 1-2 example files showing:
- A well-structured component/module in this codebase
- Common patterns to follow

## Output

After completing each file, summarize what you created:

```
✅ Context setup complete!

Created/Updated:
- CLAUDE.md - [brief description of what was added]
- .context/CONTEXT.md - [brief description]
- .context/decisions/001-xxx.md - [title]
- .context/decisions/002-xxx.md - [title]
- .context/skills/xxx/SKILL.md - [title]
```

Ask the user to review and refine any sections that need their input.
