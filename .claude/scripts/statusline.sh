#!/bin/bash
# dotcontext StatusLine script for Claude Code
# Shows: git branch, uncommitted changes, context health, model, context usage
# Receives JSON on stdin from Claude Code

# Read JSON from stdin
INPUT=$(cat)

# Extract model and context info from Claude Code's JSON
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "unknown"' 2>/dev/null)
CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)

# Git info
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -n "$BRANCH" ]; then
  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGES" -gt 0 ]; then
    GIT_INFO="${BRANCH} (+${CHANGES})"
  else
    GIT_INFO="${BRANCH}"
  fi
else
  GIT_INFO="no git"
fi

# Context health
if [ -s ".context/CONTEXT.md" ] && [ -s "CLAUDE.md" ]; then
  CTX_HEALTH="ok"
else
  CTX_HEALTH="incomplete"
fi

# Output
echo "${MODEL} | ctx:${CTX_PCT}% | ${GIT_INFO} | .context:${CTX_HEALTH}"
