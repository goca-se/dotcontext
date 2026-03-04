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
2. **If not provided:** Read `.context/CONTEXT.md` -> "External Integrations" table
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
   > "Discovery [filename] is from [date] (>30 days old). Findings may be outdated."
4. Pass cached summaries to Agent 5 for reference

### Step 5: Launch Phase 1 Agents (Parallel)

Read the following files to build context for agents:
- `.context/CONTEXT.md` (full file)
- `CLAUDE.md` (full file)
- All files in `.context/decisions/` (read each ADR)

**IMPORTANT:** Launch Agent 1, Agent 2, and Agent 3 in a SINGLE message with multiple Task tool calls. Agent 2 and Agent 3 run in background.

**Agent prompt files** — Read these files and use as agent prompts, substituting the placeholders with actual data gathered above.

---

#### Agent 1 — Compliance & Scope Guardian

Use the **Task tool** with `subagent_type: "Explore"`:

Read `.claude/agents/deep-context/scope-guardian.md` for the agent prompt. Substitute `{query}`, `{focus_areas}`, `{context_md}`, `{claude_md}`, and `{decisions}` with actual values.

---

#### Agent 2 — Primary Explorer (Background)

Use the **Task tool** with `subagent_type: "Explore"` and `run_in_background: true`:

Read `.claude/agents/deep-context/primary-explorer.md` for the agent prompt. Substitute `{query}`, `{focus_areas}`, and `{context_md}` with actual values.

---

#### Agent 3 — Cross-Repo Explorer (Background)

**Only launch this agent if a related repo was resolved in Step 2.**

Use the **Task tool** with `subagent_type: "Explore"` and `run_in_background: true`:

Read `.claude/agents/deep-context/cross-repo-explorer.md` for the agent prompt. Substitute `{query}`, `{related_repo_path}`, and `{context_md}` with actual values.

### Step 6: Wait for Phase 1 Completion

1. Agent 1 completes first (foreground) — save its scope definition
2. Read Agent 2's output (background task) — save its findings
3. Read Agent 3's output (background task, if launched) — save its findings

### Step 7: Launch Agent 4 — Cross-Repo Validator

**Only launch if Agent 3 was used (cross-repo analysis exists).**

Use the **Task tool** with `subagent_type: "general-purpose"`:

Read `.claude/agents/deep-context/cross-repo-validator.md` for the agent prompt. Substitute `{query}`, `{scope_definition}`, `{primary_findings}`, and `{cross_repo_findings}` with actual agent outputs.

### Step 8: Launch Agent 5 — Reviewer & Output Generator

Use the **Task tool** with `subagent_type: "general-purpose"`:

Read `.claude/agents/deep-context/reviewer-output.md` for the agent prompt. Substitute all placeholders with actual data:
- `{query}`, `{repos}`, `{date}` — basic info
- `{scope_output}` — Agent 1 output
- `{primary_output}` — Agent 2 output
- `{cross_repo_section}` — Agent 3 + Agent 4 outputs (if applicable, otherwise empty)
- `{cache_section}` — cached discovery summaries (if --cache, otherwise empty)
- `{cache_status}` — "enabled" or "disabled"
- `{previous_discoveries}` — list of referenced files or "none"

### Step 9: Save Output

1. Generate filename: `YYYYMMDD-{slugified-query}.md`
   - Slug: lowercase, hyphens instead of spaces, no special chars
   - If file exists, append `-2`, `-3`, etc.
2. Write the document to `.context/discoveries/{filename}`
3. Display a summary in the terminal:

```
Deep Context analysis complete

Saved to: .context/discoveries/{filename}

Summary:
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
