# Skill: Git Platform Detection

## When to Use

Before running any git hosting CLI command (creating PRs, viewing issues, commenting on PRs, etc.), detect the platform first. Never assume GitHub.

## Detection

Run this detection sequence and use the FIRST match:

### Step 1: Check remote URL

```bash
git remote get-url origin 2>/dev/null
```

| Remote URL contains | Platform | CLI | MR/PR term |
|---------------------|----------|-----|------------|
| `github.com` | GitHub | `gh` | Pull Request (PR) |
| `gitlab.com` or `gitlab` | GitLab | `glab` | Merge Request (MR) |
| `bitbucket.org` | Bitbucket | `bb` or API | Pull Request (PR) |
| `dev.azure.com` or `visualstudio.com` | Azure DevOps | `az repos` | Pull Request (PR) |
| `codecommit` | AWS CodeCommit | `aws codecommit` | Pull Request (PR) |

For self-hosted instances (e.g., `gitlab.company.com`), check for platform indicators:
- `.gitlab-ci.yml` exists → GitLab
- `.github/` directory exists → GitHub
- `bitbucket-pipelines.yml` exists → Bitbucket
- `azure-pipelines.yml` exists → Azure DevOps

### Step 2: Verify CLI is installed

```bash
# GitHub
command -v gh &>/dev/null && gh auth status &>/dev/null

# GitLab
command -v glab &>/dev/null && glab auth status &>/dev/null

# Azure DevOps
command -v az &>/dev/null && az devops configure --list &>/dev/null
```

If the CLI is not installed, inform the user and provide the install command:
- GitHub: `brew install gh` / `sudo apt install gh`
- GitLab: `brew install glab` / `sudo apt install glab`
- Azure DevOps: `az extension add --name azure-devops`

### Step 3: If detection fails

**Use AskUserQuestion** with options:
- "GitHub (gh)"
- "GitLab (glab)"
- "Azure DevOps (az repos)"
- "Other (I'll provide the commands)"

## Command Reference

### Create PR/MR

| Platform | Command |
|----------|---------|
| GitHub | `gh pr create --title "..." --body "..."` |
| GitLab | `glab mr create --title "..." --description "..."` |
| Azure DevOps | `az repos pr create --title "..." --description "..."` |

### View PR/MR

| Platform | Command |
|----------|---------|
| GitHub | `gh pr view [N] --json title,body,state,comments` |
| GitLab | `glab mr view [N]` |
| Azure DevOps | `az repos pr show --id [N]` |

### Comment on PR/MR

| Platform | Command |
|----------|---------|
| GitHub | `gh pr comment [N] --body "..."` |
| GitLab | `glab mr note [N] --message "..."` |
| Azure DevOps | `az repos pr set-vote --id [N]` (or API for comments) |

### Get PR/MR diff

| Platform | Command |
|----------|---------|
| GitHub | `gh pr diff [N]` |
| GitLab | `glab mr diff [N]` |
| Azure DevOps | `az repos pr diff --id [N]` |

### View issue

| Platform | Command |
|----------|---------|
| GitHub | `gh issue view [N] --json title,body,comments` |
| GitLab | `glab issue view [N]` |
| Azure DevOps | `az boards work-item show --id [N]` |

### Review PR/MR

| Platform | Command |
|----------|---------|
| GitHub | `gh pr review [N] --comment --body "..."` |
| GitLab | `glab mr approve [N]` / `glab mr note [N]` |
| Azure DevOps | `az repos pr set-vote --id [N] --vote approve` |

### List PRs/MRs

| Platform | Command |
|----------|---------|
| GitHub | `gh pr list` |
| GitLab | `glab mr list` |
| Azure DevOps | `az repos pr list` |
