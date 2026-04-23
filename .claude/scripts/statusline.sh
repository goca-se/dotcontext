#!/usr/bin/env bash
# dotcontext StatusLine script for Claude Code
# Shows: model, directory, git branch, context usage (with 1M-context awareness),
#        session cost, duration, net lines, and .context health.
# Dependencies: jq (required), awk, grep, tail
# Receives JSON on stdin from Claude Code's statusLine hook.

set -uo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf '[statusline] jq not installed — install jq to enable this status line\n'
  exit 0
fi

# --- ANSI colors ---
RED='\033[31m'
RED_BOLD='\033[31;1m'
RED_BRIGHT='\033[91m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[94m'
GRAY='\033[90m'
RESET='\033[0m'

# --- Extract fields from hook JSON ---
MODEL_NAME=$(printf '%s' "$INPUT" | jq -r '.model.display_name // "Claude"')
MODEL_ID=$(printf '%s' "$INPUT" | jq -r '.model.id // ""')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""')
CURRENT_DIR=$(printf '%s' "$INPUT" | jq -r '.workspace.current_dir // ""')
PROJECT_DIR=$(printf '%s' "$INPUT" | jq -r '.workspace.project_dir // ""')
COST_USD=$(printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(printf '%s' "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(printf '%s' "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(printf '%s' "$INPUT" | jq -r '.cost.total_lines_removed // 0')

# --- Detect context window (1M vs 200k) ---
# Opus 4.7's extended 1M context mode shows "1M" in display_name and "[1m]" in id.
if [[ "$MODEL_NAME" == *"1M"* ]] || [[ "$MODEL_ID" == *"[1m]"* ]]; then
  CTX_WINDOW=1000000
else
  CTX_WINDOW=200000
fi

# --- Parse transcript JSONL for most recent usage ---
# Walks the last 15 lines in reverse until it finds either an assistant
# message with usage fields, or a system_message carrying an auto-compact
# / low-context warning.
PERCENT=0
TOKENS=0
WARNING=""
FOUND_USAGE=0

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue

    TYPE=$(printf '%s' "$line" | jq -r '.type // empty' 2>/dev/null)

    if [ "$TYPE" = "assistant" ]; then
      INPUT_TOKENS=$(printf '%s' "$line" | jq -r '.message.usage.input_tokens // 0' 2>/dev/null)
      CACHE_READ=$(printf '%s' "$line" | jq -r '.message.usage.cache_read_input_tokens // 0' 2>/dev/null)
      CACHE_CREATE=$(printf '%s' "$line" | jq -r '.message.usage.cache_creation_input_tokens // 0' 2>/dev/null)
      TOKENS=$((INPUT_TOKENS + CACHE_READ + CACHE_CREATE))
      if [ "$TOKENS" -gt 0 ]; then
        PERCENT=$((TOKENS * 100 / CTX_WINDOW))
        [ "$PERCENT" -gt 100 ] && PERCENT=100
        FOUND_USAGE=1
        break
      fi
    elif [ "$TYPE" = "system_message" ]; then
      CONTENT=$(printf '%s' "$line" | jq -r '.content // empty' 2>/dev/null)
      if printf '%s' "$CONTENT" | grep -qE 'Context left until auto-compact: [0-9]+%'; then
        LEFT=$(printf '%s' "$CONTENT" | grep -oE 'Context left until auto-compact: [0-9]+%' | grep -oE '[0-9]+')
        PERCENT=$((100 - LEFT))
        WARNING="auto-compact"
        FOUND_USAGE=1
        break
      elif printf '%s' "$CONTENT" | grep -qE 'Context low \([0-9]+% remaining\)'; then
        LEFT=$(printf '%s' "$CONTENT" | grep -oE '\([0-9]+%' | grep -oE '[0-9]+')
        PERCENT=$((100 - LEFT))
        WARNING="low"
        FOUND_USAGE=1
        break
      fi
    fi
  done < <(tail -n 15 "$TRANSCRIPT" 2>/dev/null | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--)print a[i]}')
fi

# --- Build context indicator ---
if [ "$FOUND_USAGE" -eq 0 ]; then
  CTX_DISPLAY="🔵 ???"
  MODEL_COLOR="$BLUE"
else
  if [ "$PERCENT" -ge 95 ]; then
    ICON="🚨"; CTX_COLOR="$RED_BOLD"; ALERT=" CRIT"
  elif [ "$PERCENT" -ge 90 ]; then
    ICON="🔴"; CTX_COLOR="$RED"; ALERT=" HIGH"
  elif [ "$PERCENT" -ge 75 ]; then
    ICON="🟠"; CTX_COLOR="$RED_BRIGHT"; ALERT=""
  elif [ "$PERCENT" -ge 50 ]; then
    ICON="🟡"; CTX_COLOR="$YELLOW"; ALERT=""
  else
    ICON="🟢"; CTX_COLOR="$GREEN"; ALERT=""
  fi

  [ "$WARNING" = "auto-compact" ] && ALERT=" AUTO-COMPACT!"
  [ "$WARNING" = "low" ] && ALERT=" LOW!"

  SEGMENTS=8
  FILLED=$((PERCENT * SEGMENTS / 100))
  [ "$FILLED" -gt "$SEGMENTS" ] && FILLED="$SEGMENTS"
  BAR=""
  i=0
  while [ "$i" -lt "$FILLED" ]; do BAR="${BAR}█"; i=$((i+1)); done
  while [ "$i" -lt "$SEGMENTS" ]; do BAR="${BAR}▁"; i=$((i+1)); done

  CTX_DISPLAY="${ICON}${CTX_COLOR}${BAR}${RESET} ${PERCENT}%${ALERT}"

  if [ "$PERCENT" -ge 90 ]; then
    MODEL_COLOR="$RED"
  elif [ "$PERCENT" -ge 75 ]; then
    MODEL_COLOR="$YELLOW"
  else
    MODEL_COLOR="$GREEN"
  fi
fi

MODEL_DISPLAY="${MODEL_COLOR}[${MODEL_NAME}]${RESET}"

# --- Directory (relative to project root when nested) ---
if [ -n "$CURRENT_DIR" ] && [ -n "$PROJECT_DIR" ]; then
  case "$CURRENT_DIR" in
    "$PROJECT_DIR"*)
      REL="${CURRENT_DIR#"$PROJECT_DIR"}"
      REL="${REL#/}"
      DIR="${REL:-$(basename "$PROJECT_DIR")}"
      ;;
    *)
      DIR=$(basename "$CURRENT_DIR")
      ;;
  esac
elif [ -n "$PROJECT_DIR" ]; then
  DIR=$(basename "$PROJECT_DIR")
elif [ -n "$CURRENT_DIR" ]; then
  DIR=$(basename "$CURRENT_DIR")
else
  DIR="unknown"
fi

# --- Git branch + change count ---
GIT_INFO=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGES" -gt 0 ]; then
      GIT_INFO=" ${GRAY}|${RESET} ${RED}🌿 ${BRANCH} (${CHANGES})${RESET}"
    else
      GIT_INFO=" ${GRAY}|${RESET} ${GREEN}🌿 ${BRANCH}${RESET}"
    fi
  fi
fi

# --- Session metrics: cost / duration / net lines ---
METRICS=""

COST_POS=$(awk -v c="$COST_USD" 'BEGIN{print (c+0 > 0) ? 1 : 0}')
if [ "$COST_POS" = "1" ]; then
  COST_HI=$(awk -v c="$COST_USD" 'BEGIN{print (c+0 >= 0.10) ? 1 : 0}')
  COST_MID=$(awk -v c="$COST_USD" 'BEGIN{print (c+0 >= 0.05) ? 1 : 0}')
  if [ "$COST_HI" = "1" ]; then COST_COLOR="$RED"
  elif [ "$COST_MID" = "1" ]; then COST_COLOR="$YELLOW"
  else COST_COLOR="$GREEN"
  fi
  COST_SMALL=$(awk -v c="$COST_USD" 'BEGIN{print (c+0 < 0.01) ? 1 : 0}')
  if [ "$COST_SMALL" = "1" ]; then
    COST_STR=$(awk -v c="$COST_USD" 'BEGIN{printf "%d¢", c*100}')
  else
    COST_STR=$(awk -v c="$COST_USD" 'BEGIN{printf "$%.3f", c}')
  fi
  METRICS="${METRICS}${COST_COLOR}💰 ${COST_STR}${RESET} "
fi

if [ "$DURATION_MS" -gt 0 ]; then
  MINUTES=$((DURATION_MS / 60000))
  if [ "$MINUTES" -ge 30 ]; then DUR_COLOR="$YELLOW"; else DUR_COLOR="$GREEN"; fi
  if [ "$MINUTES" -lt 1 ]; then
    DUR_STR="$((DURATION_MS / 1000))s"
  else
    DUR_STR="${MINUTES}m"
  fi
  METRICS="${METRICS}${DUR_COLOR}⏱ ${DUR_STR}${RESET} "
fi

if [ "$LINES_ADDED" -gt 0 ] || [ "$LINES_REMOVED" -gt 0 ]; then
  NET=$((LINES_ADDED - LINES_REMOVED))
  if [ "$NET" -gt 0 ]; then LINES_COLOR="$GREEN"; SIGN="+"
  elif [ "$NET" -lt 0 ]; then LINES_COLOR="$RED"; SIGN=""
  else LINES_COLOR="$YELLOW"; SIGN=""
  fi
  METRICS="${METRICS}${LINES_COLOR}📝 ${SIGN}${NET}${RESET} "
fi

METRICS="${METRICS% }"
[ -n "$METRICS" ] && METRICS=" ${GRAY}|${RESET} ${METRICS}"

# --- .context health ---
if [ -s ".context/CONTEXT.md" ] && [ -s "CLAUDE.md" ]; then
  HEALTH=""
else
  HEALTH=" ${GRAY}|${RESET} ${YELLOW}⚠ .context:incomplete${RESET}"
fi

# --- Final output ---
printf '%b %b📁 %s%b%b 🧠 %b%b%b\n' \
  "$MODEL_DISPLAY" "$YELLOW" "$DIR" "$RESET" "$GIT_INFO" "$CTX_DISPLAY" "$METRICS" "$HEALTH"
