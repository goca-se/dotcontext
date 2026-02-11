# Deep Context — Multi-Agent Business Rule Discovery

Orchestrate 5 specialized agents to discover business rules across the current repository and a related repository. Produces a structured discovery document with executive summary, detailed findings, code references, and cross-repo validation.

**Usage:** `/deep-context [query]`
- `/deep-context "checkout flow"` — Search main repo only (auto-detects related repo from CONTEXT.md)
- `/deep-context "checkout flow" --repo ~/path/to/api` — Specify related repo path
- `/deep-context "checkout flow" --repo git@github.com:org/api` — Clone remote repo temporarily
- `/deep-context "payment rules" --cache` — Reference previous discoveries

## Process

### Step 1: Parse Arguments

Extract from `$ARGUMENTS`:
- **query**: The business domain/flow to investigate (required)
- **--repo [path|url]**: Path to related repository (optional)
- **--cache**: Reference previous discoveries in `.context/discoveries/` (optional)

If no query is provided, **use AskUserQuestion** to ask:
> "What business domain, flow, or set of rules do you want to investigate?"
> Options: suggest 3-4 based on `.context/CONTEXT.md` Main Flows section, plus "Other"

### Step 2: Resolve Related Repository

1. **If `--repo` was provided:** Use that path/URL directly
2. **If not provided:** Read `.context/CONTEXT.md` → "External Integrations" table
   - Look for entries with Type containing "API", "Service", "Frontend", "Backend", "Repo"
   - If integrations found, **use AskUserQuestion**:
     > "I found these external integrations in CONTEXT.md. Which is related to '[query]'?"
     > Options: [list integrations] + "None — search this repo only" + "Other (specify path)"
   - If no integrations found, **use AskUserQuestion**:
     > "No external integrations found in CONTEXT.md. Is there a related repository for cross-repo analysis?"
     > Options: "Yes, I'll provide the path or URL" | "No, search this repo only"
   - If user provides a path/URL, use it as RELATED_REPO_PATH

3. **If repo is a URL (git@... or https://...):**
   - **Use AskUserQuestion:**
     > "The related repo isn't available locally. Should I clone it temporarily?"
     > Options: "Yes, clone to /tmp" | "No, skip cross-repo analysis"
   - If yes: `git clone --depth 1 [url] /tmp/deep-context-related-repo`
   - Set RELATED_REPO_PATH to the cloned path
   - Remember to clean up after completion

4. **If repo is a local path:** Verify it exists with `ls [path]/.git`

### Step 3: Gather Scope Context

**Use AskUserQuestion** to refine the search scope:
> "To focus the analysis of '[query]', which areas are most relevant?"
> Options (multiSelect: true):
> - "Models & data validation" — Entity schemas, database constraints, model validations
> - "API endpoints & controllers" — Request handling, response formatting, route definitions
> - "Business logic & services" — Core domain logic, service layer, use cases
> - "Frontend forms & UI validation" — Client-side validation, form logic, UI constraints
> - "Configuration & feature flags" — Environment configs, toggles, thresholds
> - "Tests & specifications" — Test assertions that document expected behavior

### Step 4: Load Cache (if --cache)

If `--cache` flag is present:
1. Read all files in `.context/discoveries/*.md`
2. For each file, extract the "Executive Summary" and "Business Rules Discovered" sections
3. Note the date — if any discovery is older than 30 days, warn:
   > "⚠ Discovery [filename] is from [date] (>30 days old). Findings may be outdated."
4. Pass cached summaries to Agent 5 for reference

### Step 5: Launch Phase 1 Agents (Parallel)

Read the following files to build context for agents:
- `.context/CONTEXT.md` (full file)
- `CLAUDE.md` (full file)
- All files in `.context/decisions/` (read each ADR)

**IMPORTANT:** Launch Agent 1, Agent 2, and Agent 3 in a SINGLE message with multiple Task tool calls. Agent 2 and Agent 3 run in background.

---

#### Agent 1 — Compliance & Scope Guardian

Use the **Task tool** with `subagent_type: "Explore"`:

```
You are the Compliance & Scope Guardian agent for a deep business rule discovery.

**Your mission:** Build a scope definition for the query and identify project boundaries.

**Query:** {query}
**User-selected focus areas:** {areas from Step 3}

**Project context:**
{paste CONTEXT.md content}

**CLAUDE.md rules:**
{paste CLAUDE.md content}

**Existing decisions:**
{paste ADR summaries}

**Instructions:**
1. Analyze the query against the project's domain entities, modules, and flows
2. Identify which entities, modules, and files are relevant to this query
3. Identify compliance constraints from ADRs that affect this domain
4. Score each identified area for relevance:
   - **In-scope (>80%)**: Directly related to the query
   - **Borderline (50-80%)**: Tangentially related, may contain relevant rules
   - **Out-of-scope (<50%)**: Not related, should be excluded

**Output this exact format:**

## Scope Definition

### Query Interpretation
[1-2 sentences explaining what business domain this query covers]

### In-Scope Entities
| Entity | Relevance | Why |
|--------|-----------|-----|

### In-Scope Modules/Directories
| Path Pattern | Relevance | Why |
|--------------|-----------|-----|

### Relevant ADRs
| ADR | How it relates |
|-----|----------------|

### Search Keywords
[Comma-separated list of terms, function names, class names to search for]

### Out-of-Scope (exclude these)
[List of modules/entities that are NOT related to the query]
```

---

#### Agent 2 — Primary Explorer (Background)

Use the **Task tool** with `subagent_type: "Explore"` and `run_in_background: true`:

```
You are the Primary Explorer agent for a deep business rule discovery.

**Your mission:** Deep search the main repository for ALL business rules related to the query.

**Query:** {query}
**User-selected focus areas:** {areas from Step 3}

**Project context (from CONTEXT.md):**
{paste relevant sections}

**Instructions:**
1. Search thoroughly using Grep and Glob tools
2. Look in these areas (based on user focus):
   - Models: validation rules, constraints, enums, constants
   - Controllers/Routes: parameter validation, authorization checks, business logic
   - Services: domain logic, calculations, state machines, workflows
   - Middleware: authentication, rate limiting, request transformation
   - Config: feature flags, thresholds, limits, environment-specific rules
   - Tests: assertions that document expected behavior (these ARE business rules)
   - Database: migrations, schema constraints, indexes
3. For EVERY finding, you MUST include the exact file path and line number
4. Do NOT fabricate or assume — only report what you find in actual code
5. Group findings by category

**Output this exact format:**

## Primary Repo Findings

### [Category: e.g., "Validation Rules"]

#### Finding 1: [Short title]
- **File:** [exact/path/to/file.ext]
- **Lines:** [start-end]
- **Code:**
```
[exact code snippet]
```
- **Rule:** [Plain English description of the business rule]
- **Confidence:** [50-100]%

#### Finding 2: ...

### [Category: e.g., "Authorization"]
...

## Summary Statistics
- Total findings: [N]
- Categories: [list]
- Files analyzed: [list of key files with line ranges]
```

---

#### Agent 3 — Cross-Repo Explorer (Background)

**Only launch this agent if a related repo was resolved in Step 2.**

Use the **Task tool** with `subagent_type: "Explore"` and `run_in_background: true`:

```
You are the Cross-Repo Explorer agent for a deep business rule discovery.

**Your mission:** Explore the related repository for business rules corresponding to the query.

**Query:** {query}
**Related repo path:** {RELATED_REPO_PATH}
**Main repo context (from CONTEXT.md):**
{paste relevant sections — especially External Integrations}

**Instructions:**
1. Search the related repo at {RELATED_REPO_PATH} using Grep and Glob
2. Focus on finding:
   - API endpoints that the main repo calls (or that call the main repo)
   - Shared types, interfaces, or contracts
   - Validation logic that mirrors or extends main repo rules
   - Error handling and error codes
   - Configuration and environment variables
   - Tests that document expected behavior
3. Map findings to main repo concepts where possible
4. For EVERY finding, include exact file path and line number (relative to related repo root)
5. Do NOT fabricate — only report what exists in code

**Output this exact format:**

## Cross-Repo Findings ({related repo name})

### [Category: e.g., "API Contracts"]

#### Finding 1: [Short title]
- **File:** [exact/path/to/file.ext]
- **Lines:** [start-end]
- **Code:**
```
[exact code snippet]
```
- **Rule:** [Plain English description]
- **Maps to main repo:** [which main repo concept/entity this relates to]
- **Confidence:** [50-100]%

### [Category: e.g., "Client-Side Validation"]
...

## Summary Statistics
- Total findings: [N]
- Categories: [list]
- Files analyzed: [list of key files with line ranges]
```

### Step 6: Wait for Phase 1 Completion

1. Agent 1 completes first (foreground) — save its scope definition
2. Read Agent 2's output (background task) — save its findings
3. Read Agent 3's output (background task, if launched) — save its findings

### Step 7: Launch Agent 4 — Cross-Repo Validator

**Only launch if Agent 3 was used (cross-repo analysis exists).**

Use the **Task tool** with `subagent_type: "general-purpose"`:

```
You are the Cross-Repo Validator agent for a deep business rule discovery.

**Your mission:** Compare business rules between the main repo and related repo. Find matches, contradictions, and gaps.

**Query:** {query}

**Agent 1 Scope Definition:**
{paste Agent 1 output}

**Agent 2 Primary Repo Findings:**
{paste Agent 2 output}

**Agent 3 Cross-Repo Findings:**
{paste Agent 3 output}

**Instructions:**
1. Compare each finding from Agent 2 against Agent 3's findings
2. Classify each comparison as:
   - **Match**: Same rule enforced in both repos (consistent)
   - **Contradiction**: Different rules for the same concept (inconsistent)
   - **Gap**: Rule exists in one repo but not the other (missing)
3. For contradictions, explain exactly what differs
4. For gaps, recommend whether the missing rule should be added
5. Only report comparisons backed by actual code references from Agents 2 and 3

**Output this exact format:**

## Cross-Repo Validation

### Matches ✓
| Rule | Main Repo (file:line) | Related Repo (file:line) | Notes |
|------|----------------------|--------------------------|-------|

### Contradictions ✗
| Issue | Main Repo Says (file:line) | Related Repo Says (file:line) | Impact |
|-------|---------------------------|-------------------------------|--------|

### Gaps ⚠
| Missing In | Rule Description | Present In (file:line) | Recommendation |
|------------|------------------|------------------------|----------------|

### Summary
- Matches: [N]
- Contradictions: [N]
- Gaps: [N]
- Overall consistency: [High/Medium/Low]
```

### Step 8: Launch Agent 5 — Reviewer & Output Generator

Use the **Task tool** with `subagent_type: "general-purpose"`:

```
You are the Reviewer & Output Generator agent for a deep business rule discovery.

**Your mission:** Produce the final discovery document by unifying all agent outputs. Apply quality filters and format the output.

**Query:** {query}
**Repos analyzed:** {main repo name} {+ related repo name if applicable}
**Date:** {today's date YYYY-MM-DD}

**Agent 1 (Scope Guardian) Output:**
{paste Agent 1 output}

**Agent 2 (Primary Explorer) Output:**
{paste Agent 2 output}

{if Agent 3 was used:}
**Agent 3 (Cross-Repo Explorer) Output:**
{paste Agent 3 output}

**Agent 4 (Validator) Output:**
{paste Agent 4 output}

{if --cache was used:}
**Previous Discoveries (for reference):**
{paste cached discovery summaries}

**Instructions:**
1. **Filter**: Remove any finding with Confidence < 50% (from Agents 2 and 3)
2. **Deduplicate**: If the same rule appears in multiple agents' outputs, keep the most detailed version
3. **Categorize**: Group findings into logical business categories
4. **Verify**: Every finding in the final document MUST have a file:line reference. Remove any that don't.
5. **Summarize**: Write a 3-5 bullet executive summary of the most important discoveries
6. **Never invent**: You are a compiler, not a creator. Only include what agents actually found.
7. If cache was provided, note any findings that confirm or update previous discoveries

**Output the COMPLETE document in this exact format:**

# Deep Context: {query}
> Generated: {YYYY-MM-DD} | Repos: {main repo}{, related repo if applicable}

## Executive Summary
- [Key finding 1]
- [Key finding 2]
- [Key finding 3]
- Confidence: [X] findings validated, [Y] contradictions found

## Business Rules Discovered

### [Category 1]
| Rule | Source | File:Line | Confidence |
|------|--------|-----------|------------|
| [description] | [repo name] | [path:line] | [N]% |

#### Details
[Expanded explanation with code snippets for important rules in this category]

### [Category 2]
| Rule | Source | File:Line | Confidence |
|------|--------|-----------|------------|

#### Details
...

{if cross-repo analysis was done:}
## Cross-Repo Validation

### Matches ✓
| Rule | Main Repo | Related Repo | Status |
|------|-----------|--------------|--------|

### Contradictions ✗
| Issue | Main Repo Says | Related Repo Says | Files |
|-------|---------------|-------------------|-------|

### Gaps ⚠
| Missing In | Rule | Present In | Recommendation |
|------------|------|------------|----------------|

## References
- [List of all files analyzed with line ranges, grouped by repo]

## Metadata
- Query: {original query}
- Repos analyzed: {list}
- Agents: 5 | Confidence threshold: 50%
- Cache: {enabled/disabled}
- Previous discoveries referenced: {list or none}
```

### Step 9: Save Output

1. Generate filename: `YYYYMMDD-{slugified-query}.md`
   - Slug: lowercase, hyphens instead of spaces, no special chars
   - If file exists, append `-2`, `-3`, etc.
2. Write the document to `.context/discoveries/{filename}`
3. Display a summary in the terminal:

```
✅ Deep Context analysis complete

📄 Saved to: .context/discoveries/{filename}

📊 Summary:
- [N] business rules discovered
- [N] cross-repo validations
- [N] contradictions found
- [N] gaps identified

Key findings:
[paste executive summary bullets]
```

### Step 10: Cleanup

- If a temporary clone was created in Step 2, remove it:
  ```bash
  rm -rf /tmp/deep-context-related-repo
  ```

## Guidelines

### Factual Accuracy
- Every finding MUST reference a specific file and line number
- Agents use Grep and Glob to search — never fabricate code or file paths
- If unsure about a finding, include it with lower confidence score
- Agent 5 removes anything below 50% confidence

### Agent Communication
- Agents communicate through the orchestrator (this command)
- No temp files — data passes through Task tool returns
- Phase 1 agents run in parallel; Phase 2-3 are sequential
- See ADR-009 for the orchestration pattern

### Output Format
- Follows ADR-010: Discovery Output Format
- Plain markdown with tables
- Saved to `.context/discoveries/`
- Never overwrites existing files

### Performance
- Agents use focused Grep/Glob searches, not full file reads
- Agent 1 narrows scope early to prevent context overflow
- Background agents (2, 3) run in parallel for speed
- Set `max_turns: 30` on explorer agents to prevent runaway searches

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
