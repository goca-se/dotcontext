# Release

Create a new release with automatic version bumping, changelog update, and GitHub release.

## Process

### 1. Analyze Changes

First, gather context about what's being released:

```bash
# Get current version
grep -E "^VERSION=" dotcontext | cut -d'"' -f2

# Get latest tag
git tag --sort=-v:refname | head -1

# See unreleased commits
git log $(git tag --sort=-v:refname | head -1)..HEAD --oneline

# Check for pending changes
git status --short
```

### 2. Determine Version Bump

Analyze the commits since last release to suggest the version bump type.

**Use AskUserQuestion tool** with these options:

- **patch** (x.y.Z) - Bug fixes, small improvements, documentation
  - Fixes that don't change behavior significantly
  - Performance improvements
  - Dependency updates

- **minor** (x.Y.0) - New features, backward-compatible changes
  - New commands or options
  - New functionality
  - Deprecations (but not removals)

- **major** (X.0.0) - Breaking changes
  - Removed commands or options
  - Changed behavior that breaks existing usage
  - API/interface changes

Show the user the commits and your recommendation based on conventional commit prefixes:
- `feat:` → suggests minor
- `fix:`, `chore:`, `docs:`, `perf:` → suggests patch
- `feat!:`, `fix!:`, or `BREAKING CHANGE` → suggests major

### 3. Calculate New Version

Parse current version and increment appropriately:

```bash
# Example: if current is 0.8.1
# patch → 0.8.2
# minor → 0.9.0
# major → 1.0.0
```

### 4. Review Staged Changes

If there are uncommitted changes, show them and ask:

**Use AskUserQuestion tool:**
- "Include these uncommitted changes in the release?"
- Options: "Yes, stage and include" / "No, release only committed changes" / "Cancel, I need to commit first"

### 5. Generate Changelog Entry

Based on commits since last release, generate a changelog entry:

```markdown
## [X.Y.Z](https://github.com/goca-se/dotcontext/compare/vOLD...vNEW) (YYYY-MM-DD)

### Features (if any feat: commits)
* **feature name** - description

### Fixes (if any fix: commits)
* **fix name** - description

### Changes (if any other significant commits)
* description
```

Show the generated changelog to the user and ask for confirmation.

### 6. Apply Changes

Once confirmed:

1. **Update version in `src/header.sh`** (the single source of truth) and rebuild — **never** sed the built `dotcontext` directly, or the binary will drift from source:
```bash
sed -i '' "s/VERSION=\".*\"/VERSION=\"X.Y.Z\"/" src/header.sh
make build
```

2. **Update CHANGELOG.md** - prepend the new entry after `# Changelog`

3. **Commit changes** (must include both `src/header.sh` and the rebuilt `dotcontext`):
```bash
git add -A
git commit -m "chore(release): vX.Y.Z"
```

4. **Create tag:**
```bash
git tag vX.Y.Z
```

### 7. Push (the release is created automatically)

**Use AskUserQuestion tool:**
- "Push and trigger the release workflow?"
- Options: "Yes, push" / "No, keep local only"

If yes:
```bash
git push && git push --tags
```

Pushing the `vX.Y.Z` tag triggers `.github/workflows/release.yml`, which verifies the
binary is in sync, checks the tag matches `VERSION`, generates notes from the git log,
and runs `gh release create`. **Do not** call `gh release create` by hand — the workflow
owns that. After pushing, confirm the run succeeded:
```bash
gh run watch --exit-status || gh run list --workflow=release.yml --limit 1
```

### 8. Output

```
✅ Released vX.Y.Z

- Commit: <hash>
- Tag: vX.Y.Z
- Release: https://github.com/goca-se/dotcontext/releases/tag/vX.Y.Z

Changelog:
<summary of changes>
```

## Arguments

- `$ARGUMENTS` can optionally specify the version type: `patch`, `minor`, or `major`
- If provided, skip the version type question

## Important

- **Never skip the changelog review** - always show the user what will be in the release notes
- **Never force push** - if push fails, stop and inform the user
- **Validate version format** - ensure it follows semver (X.Y.Z)
- If anything fails, stop immediately and explain what went wrong

## If You Get Stuck

If you cannot make progress after 3 attempts at the same step:
1. Stop immediately
2. Explain what you're trying to do and what's blocking you
3. **Use AskUserQuestion tool** to ask the user how to proceed
