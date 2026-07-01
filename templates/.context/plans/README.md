# Plans

Implementation plans — the **HOW**. Written by `/plan-dc` from a spec, one file per feature:

```
plan-<unix-timestamp>-<descriptive-kebab>.md
```

A plan lists the exact files to create/modify, the tests, the verification/regression checks,
a Traceability table proving 100% coverage of the spec, and any ADR impact. `/plan-dc` runs a
dual adversarial review before a plan is considered done; `/execute-dc` treats the plan as an
immutable contract.

Flow: `/spec-dc` (WHAT) → `/plan-dc` (HOW) → `/execute-dc` (DO).
