# Specs

Behavior specifications — the **WHAT**. Written by `/spec-dc`, one file per feature:

```
spec-<unix-timestamp>-<descriptive-kebab>.md
```

A spec describes observable behavior (inputs → outputs → guarantees), never implementation.
It is the source of truth that `/plan-dc` turns into a plan and that everything downstream is
measured against.

Flow: `/spec-dc` (WHAT) → `/plan-dc` (HOW) → `/execute-dc` (DO).
