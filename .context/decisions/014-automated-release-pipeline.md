# ADR-014: Automated Release Pipeline & Single-Source Versioning

**Status:** Accepted
**Date:** 2026-06-02
**Version:** 1.0
**Deciders:** Nicholas (Gocase)

## Context

The `dotcontext` CLI is a single executable bundled from `src/` modules via `make build`
(`cat src/*.sh > dotcontext`). `src/header.sh` defines the authoritative `VERSION`.

The previous `/release` flow bumped the version with `sed` against the **built** `dotcontext`
file, never touching `src/header.sh`. This created a real drift hazard: a later `make build`
would regenerate `dotcontext` from the stale `src/header.sh` and silently **downgrade** the
released version. Releases were also fully manual (`gh release create` by hand), with
hand-authored release notes and no guard that the committed binary matched source.

Inspired by github/spec-kit's tag-triggered release workflow, which generates notes from
`git log` and runs on a pushed tag.

## Decision

1. **`src/header.sh` is the single source of truth for `VERSION`.** The `/release` flow bumps
   it and runs `make build`; it must never `sed` the built `dotcontext` directly.

2. **Releases are automated via `.github/workflows/release.yml`**, triggered on `push` of a
   `v*` tag. The workflow:
   - runs `make build` and fails if the committed `dotcontext` is out of sync with `src/`,
   - fails if the tag does not match the binary's `VERSION`,
   - takes release notes from the matching `CHANGELOG.md` section (falling back to `git log --no-merges`
     since the previous tag when no section exists), since squash-merges make the git log too sparse,
   - runs `gh release create`. Humans must not call `gh release create` by hand.

3. **A CI workflow (`.github/workflows/ci.yml`)** runs on PRs and pushes to `main`:
   `bash -n` on all modules + the binary, and the same build-in-sync check. This catches the
   drift class of bug before it can ship.

## Consequences

### Positive
- Version can no longer drift between source and binary (guarded in CI and at release).
- Pushing a tag is the entire release action; notes are generated automatically.
- Build-in-sync check prevents shipping a `dotcontext` that doesn't match `src/`.

### Negative
- Contributors must remember to `make build` and commit the binary (now enforced by CI).
- Release notes are only as good as the `CHANGELOG.md` entry for that version, so each release needs a
  written changelog section (the `git log` fallback is sparse under squash-merge).

## Alternatives Considered

1. **release-please / conventional-commit automation** — heavier; the project prefers a curated
   `CHANGELOG.md` and a manual bump decision (patch/minor/major).
2. **Generate the binary in CI instead of committing it** — breaks the "single executable you
   can `curl`" distribution model (ADR-001/ADR-002), which serves `dotcontext` from the repo.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-02 | Initial decision |

## Related
- ADR-001: Single bash executable
- ADR-002: Template download strategy
- ADR-003: Safe update behavior
