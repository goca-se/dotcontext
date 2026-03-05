# ADR-001: Single Bash Executable Architecture

**Status:** Accepted
**Date:** 2025-01-01
**Version:** 2.0
**Deciders:** Gocase Team

## Context

We needed to distribute a CLI tool that helps developers set up AI context documentation. The tool needs to:
- Be easy to install (ideally one command)
- Work across macOS, Linux, and Windows/WSL
- Have minimal dependencies
- Be simple to maintain and update

## Decision

Implement the entire CLI as a single bash script with all commands as internal functions. Source code is organized in `src/` modules (`core/`, `commands/`, `setup/`) for maintainability, bundled into a single executable via `make build`. The distributed artifact remains a single file.

## Alternatives Considered

1. **Node.js CLI** - Would require Node.js installation, npm ecosystem complexity
2. **Go binary** - Would require building for multiple platforms, larger file size
3. **Python CLI** - Would require Python installation, virtual environments
4. **Multiple shell scripts** - Would complicate installation and updates

## Consequences

### Positive
- Zero runtime dependencies (bash is ubiquitous)
- Single file to download, install, and update
- Easy to audit and understand
- Works on macOS (bash 3.2+), Linux, and WSL
- Simple `curl | bash` installation

### Negative
- Limited to what bash can do efficiently
- No package manager ecosystem (npm, pip)
- Testing is manual (no unit test framework)
- Complex logic is harder to write/maintain in bash

### Risks
- Bash version differences between macOS (3.2) and Linux (5.x)
- Must avoid bashisms not available in older versions
- Mitigation: Use POSIX-compatible constructs, test on macOS

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial decision |
| 2.0 | 2026-03-05 | Updated for modular source (src/) with build-time bundling — still ships as single file |

## Related
- ADR-002: Template download strategy
