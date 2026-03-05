# Domain Context

## Overview

[What does this system do? Who uses it? What problem does it solve?]

## Domain

### Core Entities

| Entity | Responsibility |
|--------|----------------|
| `[Entity1]` | [What it represents] |
| `[Entity2]` | [What it represents] |

### Modules/Packages

```
[directory structure of main modules]
```

## Architecture

### System Overview

[2-3 sentences: what type of system is this (monolith, microservices, serverless, CLI, library, etc.) and what architectural style does it follow?]

### Directory Structure

```
[project-root]/
├── [dir1]/          # [one-line description of module purpose]
├── [dir2]/          # [one-line description]
│   ├── [subdir]/    # [one-line description]
│   └── [subdir]/    # [one-line description]
├── [dir3]/          # [one-line description]
└── [entry-point]    # [main entry point description]
```

### Key Dependencies

| Category | Dependency | Purpose |
|----------|-----------|---------|
| Framework | [name] | [what it provides] |
| Database | [name] | [data storage approach] |
| Testing | [name] | [test framework] |
| [Other] | [name] | [purpose] |

### Data Flow

```
[High-level description of how data moves through the system]
[e.g., Request → Middleware → Controller → Service → Database]
```

## Conventions

### Naming Patterns

[e.g., camelCase for variables, PascalCase for classes, snake_case for database columns]

### Error Handling

[e.g., try/catch with custom error classes, Result types, error-first callbacks]

### Testing Style

[e.g., describe/it blocks with Jest, pytest fixtures, table-driven tests in Go]

### Import Organization

[e.g., stdlib first, then external packages, then internal modules — sorted alphabetically]

### State Management

[e.g., Redux with slices, React Context, Vuex, server-side sessions — or "N/A" if not applicable]

### API Response Format

[e.g., JSON:API, { data, error, meta } envelope, GraphQL — or "N/A" if not applicable]

## Main Flows

### [Flow 1 - e.g., Authentication]

```
[Step by step diagram or description]
```

### [Flow 2 - e.g., Main business flow]

```
[Step by step diagram or description]
```

## External Integrations

| System | Type | Description |
|--------|------|-------------|
| [System 1] | API/OAuth/etc | [What it does] |

## Glossary

| Term | Definition |
|------|------------|
| **[Term 1]** | [Definition in this project's context] |
| **[Term 2]** | [Definition in this project's context] |
