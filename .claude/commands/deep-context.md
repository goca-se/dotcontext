# Deep Context — Structured Codebase Exploration

Orchestrate 4 specialized agents in a structured progression (overview → subsystems → targeted drill → data flow mapping) to deeply explore and document a codebase domain. Produces a structured discovery document with findings, code references, and data flow analysis.

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
4. Pass cached summaries to the final output step for reference

### Step 5: Build Agent Context

Read the following files to build context for agents:
- `.context/CONTEXT.md` (full file)
- `CLAUDE.md` (full file)
- All files in `.context/decisions/` (read each ADR)

### Step 6: Launch Exploration Agents

The 4-step exploration follows a structured progression. Steps 1+2 run in parallel (both do broad exploration), then Steps 3+4 run sequentially (each needs prior outputs).

**Agent prompt files** — Read each file and substitute placeholders with actual data gathered above.

---

#### Phase 1 (Parallel): Steps 1 + 2

**IMPORTANT:** Launch both agents in a SINGLE message. Step 2 runs in background.

##### Step 1 Agent — Overview (Foreground)

Use the **Agent tool** with `subagent_type: "Explore"`, `max_turns: 30`:

Read `.claude/agents/deep-context/step1-overview.md` for the agent prompt. Substitute `{query}`, `{focus_areas}`, `{context_md}`, `{claude_md}`, and `{decisions}` with actual values.

**If a related repo was resolved in Step 2**, append to the agent prompt:
> Also explore the related repository at {related_repo_path} for its architecture and entry points.

##### Step 2 Agent — Subsystems (Background)

Use the **Agent tool** with `subagent_type: "Explore"`, `run_in_background: true`, `max_turns: 30`:

Read `.claude/agents/deep-context/step2-subsystems.md` for the agent prompt. Substitute `{query}`, `{focus_areas}`, and `{context_md}` with actual values.

**If a related repo was resolved in Step 2**, append to the agent prompt:
> Also map modules in the related repository at {related_repo_path} and their relationships to the main repo.

---

#### Wait for Phase 1 Completion

1. Step 1 Agent completes first (foreground) — save its overview output
2. Read Step 2 Agent's output (background task) — save its subsystem map

---

#### Phase 2 (Sequential): Steps 3 + 4

##### Step 3 Agent — Targeted Drill

Use the **Agent tool** with `subagent_type: "Explore"`, `max_turns: 30`:

Read `.claude/agents/deep-context/step3-drill.md` for the agent prompt. Substitute:
- `{query}`, `{focus_areas}` — from user input
- `{step1_output}` — Step 1 Agent output
- `{step2_output}` — Step 2 Agent output

##### Step 4 Agent — Data Flow Mapping

Use the **Agent tool** with `subagent_type: "general-purpose"`, `max_turns: 30`:

Read `.claude/agents/deep-context/step4-dataflow.md` for the agent prompt. Substitute:
- `{query}` — from user input
- `{step1_output}` — Step 1 Agent output
- `{step2_output}` — Step 2 Agent output
- `{step3_output}` — Step 3 Agent output

### Step 7: Compile Final Output

After all 4 agents complete, compile the final discovery document yourself. Do NOT use another agent for this.

**Compilation rules:**
1. **Filter**: Remove any finding with Confidence < 50%
2. **Deduplicate**: If the same finding appears in multiple steps, keep the most detailed version
3. **Verify**: Every finding MUST have a file:line reference — remove any that don't
4. **Never invent**: You are a compiler, not a creator. Only include what agents actually found
5. If cache was provided, note findings that confirm or update previous discoveries

**Output the document in this format:**

```markdown
# Deep Context: {query}
> Generated: {date} | Repos: {repos}

## Executive Summary
- [Key finding 1]
- [Key finding 2]
- [Key finding 3]
- [Key finding 4 if significant]

## System Overview
[Paste relevant parts from Step 1 output]

## Subsystem Map
[Paste relevant parts from Step 2 output — module inventory and relationships]

## Detailed Findings

### [Category 1]
| Finding | File:Line | Confidence |
|---------|-----------|------------|
| [description] | [path:line] | [N]% |

#### Details
[Code snippets and expanded explanations for important findings]

### [Category 2]
...

## Data Flow Analysis
[Paste flow diagrams and analysis from Step 4 output]

## Potential Issues
[Consolidate issues from Steps 3 and 4]

## References
- [List of all files analyzed with line ranges]

## Metadata
- Query: {query}
- Repos analyzed: {repos}
- Exploration steps: 4 (Overview → Subsystems → Drill → Data Flow)
- Confidence threshold: 50%
- Cache: {cache_status}
- Previous discoveries referenced: {previous_discoveries}
```

### Step 8: Save Output

1. Generate filename: `YYYYMMDD-{slugified-query}.md`
   - Slug: lowercase, hyphens instead of spaces, no special chars
   - If file exists, append `-2`, `-3`, etc.
2. Write the document to `.context/discoveries/{filename}`
3. Display a summary in the terminal:

```
Deep Context analysis complete

Saved to: .context/discoveries/{filename}

Summary:
- [N] findings discovered across [N] categories
- [N] data flows traced
- [N] potential issues identified

Key findings:
[paste executive summary bullets]
```

### Step 9: Cleanup

- If a temporary clone was created in Step 2, remove it:
  ```bash
  rm -rf /tmp/deep-context-related-repo
  ```

## Guidelines

### Factual Accuracy
- Every finding MUST reference a specific file and line number
- Agents use Grep and Glob to search — never fabricate code or file paths
- If unsure about a finding, include it with lower confidence score
- Final compilation removes anything below 50% confidence

### Agent Communication
- Agents communicate through the orchestrator (this command)
- No temp files — data passes through Agent tool returns
- Steps 1+2 run in parallel; Steps 3+4 are sequential
- See ADR-009 for the orchestration pattern
- See ADR-013 for the structured exploration pattern

### Output Format
- Follows ADR-010: Discovery Output Format
- Plain markdown with tables
- Saved to `.context/discoveries/`
- Never overwrites existing files

### Performance
- Agents use focused Grep/Glob searches, not full file reads
- Step 1 identifies key areas early to prevent unfocused exploration
- Step 2 runs in background while Step 1 executes
- Set `max_turns: 30` on all agents to prevent runaway searches

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed

Never loop indefinitely. If you find yourself repeating the same actions without progress, stop and ask for help.
