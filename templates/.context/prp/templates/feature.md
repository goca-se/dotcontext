# PRP: [Nome da Feature]

> Product Requirements Prompt — Planning document for complex features

<!--
PROGRESS TRACKING:
- Mark tasks as [x] when completed
- Mark success criteria as [x] when verified
- Update Status below when starting (In Progress) and finishing (Completed)
- Add "✅ Completed: YYYY-MM-DD" after each phase validation
-->

## Summary

[1-2 sentence description of what will be implemented]

## Context

### Problem

[What problem are we solving?]

### Affected Users

[Who uses this feature?]

### Success Criteria

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Measurable criterion 3]

## Scope

### What changes

- [Feature/functionality 1]
- [Feature/functionality 2]

### What doesn't change

> Explicit boundary against scope creep. List the things that **stay as they are** even when adjacent to the change. If a reader could reasonably assume "this gets touched too" — say it here.

- [Module/behavior that stays untouched]
- [Module/behavior that stays untouched]

## Technical Design

### Affected files

> Strict, path-level inventory. One row per file. Use `create` for new files, `modify` for edits. Keep descriptions short — the design subsections below carry the detail.

| Path | Type | Description |
|------|------|-------------|
| `src/path/to/file.ts` | modify | [short description of the change] |
| `src/path/to/new.ts` | create | [short description of the new file] |

### Design

> One subsection per logical change. **Quality rules for snippets**:
> - Every snippet must be compilable as shown — never use `// ...` or pseudo-code inside a snippet meant to be applied
> - When modifying existing code, reference the file and line (e.g., `src/auth/login.ts:83`)
> - Use real type/interface/function names from the codebase, not placeholders

#### [Change 1 title]

[Technical description with snippets ready to paste]

#### [Change 2 title]

[Technical description with snippets ready to paste]

### Data Model

<!-- Remove if no data model changes -->

```
[Schema, types, or model changes]
```

### API/Interface Changes

<!-- Remove if no API/interface changes -->

```
[New endpoints, function signatures, etc]
```

### Flow after the change

<!-- Optional. Include only when there's a meaningful flow to depict (auth, multi-step process, data pipeline). Skip for simple bug fixes. -->

```
[ASCII diagram of user/data flow after implementation]
```

## Decisions

### Impact on Existing Decisions

<!-- Remove if no existing decisions are affected -->

| ADR | Current Decision | Proposed Change | Action |
|-----|------------------|-----------------|--------|
| [ADR-XXX] | [current decision] | [what would change] | Update/Supersede/None |

### New Decisions Required

<!-- Remove if no new decisions needed -->

| Decision | Context | Options to Consider |
|----------|---------|---------------------|
| [e.g., Auth strategy] | [Why this decision is needed] | [Option A, Option B, Option C] |

**Note:** ADRs for new decisions should be created in Phase 1 before implementation begins.

---

## Validation Gate

> **Pause here.** Before generating the Implementation Plan below, the generator must:
> 1. Present a 3–5 line summary of Problem + Scope + Decisions to the user
> 2. Run the auto-validation subagent (see `/generate-prp`) in parallel
> 3. Only after user approval, fill in the Implementation Plan

---

## Implementation Plan

### Phase 1: [Name]

1. [ ] Task 1
2. [ ] Task 2
3. [ ] Task 3

**Validation:** [How to verify this phase is complete]

### Phase 2: [Name]

1. [ ] Task 1
2. [ ] Task 2

**Validation:** [How to verify this phase is complete]

### Phase N: End-to-end verification

> Always the last phase. Walk through every Success Criterion and Acceptance Criterion explicitly. Run the full build/test suite.

- [ ] Every Success Criterion from Context is verified
- [ ] `[project build command]` passes
- [ ] `[project test command]` passes
- [ ] [Any feature-specific smoke test]

## Parallelism Map

> Which phases can run in parallel during `/execute-prp`? List independent phases that touch disjoint files and have no ordering dependency. If everything is sequential, write "all phases sequential".

- Parallel block A: Phase X, Phase Y (touch disjoint modules)
- Sequential: Phase Z (must run after block A)
- Final: Phase N (e2e verification)

## Testing

### Unit Tests

```
[Files/areas to test]
```

### Integration Tests

```
[End-to-end scenarios]
```

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | High/Medium/Low | High/Medium/Low | [How to mitigate] |

## Final Checklist

> Tracks **execution state**, complementing the PRP-time auto-validation gate above.

```
[ ] Tests passing
[ ] Linting passing
[ ] Documentation updated
[ ] Reviewed by team
```

---

**Created:** YYYY-MM-DD
**Author:** [Name]
**Status:** Draft | In Progress | Completed
