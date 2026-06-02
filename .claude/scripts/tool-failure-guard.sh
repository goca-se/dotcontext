#!/bin/bash
# Tool Failure Guard for Claude Code
# Tracks consecutive failures of the same tool and injects guidance
# when the same tool fails 4+ times in a row, telling Claude to stop
# retrying and ask the user for help via AskUserQuestion.
#
# Hook event: PostToolUseFailure
# Input: JSON via stdin with tool_name, tool_input, error
# Output: JSON with additionalContext when threshold exceeded

TRACKER_FILE="/tmp/.claude-tool-failure-tracker-${SESSION_ID:-default}"
THRESHOLD=4

# Read input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // "unknown error"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')

# Update tracker file per session
TRACKER_FILE="/tmp/.claude-tool-failure-tracker-${SESSION_ID}"

# Read current state
if [ -f "$TRACKER_FILE" ]; then
  LAST_TOOL=$(head -1 "$TRACKER_FILE" 2>/dev/null)
  COUNT=$(tail -1 "$TRACKER_FILE" 2>/dev/null)
  # Validate count is a number
  if ! echo "$COUNT" | grep -qE '^[0-9]+$'; then
    COUNT=0
  fi
else
  LAST_TOOL=""
  COUNT=0
fi

# Update counter
if [ "$TOOL_NAME" = "$LAST_TOOL" ]; then
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi

# Write state
printf '%s\n%s\n' "$TOOL_NAME" "$COUNT" > "$TRACKER_FILE"

# Check threshold
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  # Reset counter so the message doesn't repeat every single failure after threshold
  printf '%s\n%s\n' "$TOOL_NAME" "0" > "$TRACKER_FILE"

  # Trigger error notification (sound + push)
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  "$SCRIPT_DIR/notify.sh" "Claude Code" "${TOOL_NAME} failed ${COUNT} times — needs your help" error &

  MSG="HOOK ALERT: The tool \"${TOOL_NAME}\" has failed ${COUNT} times consecutively. Last error: ${ERROR}. STOP retrying the same approach. You MUST use the AskUserQuestion tool to present the user with options to unblock this situation. Suggest 2-3 concrete alternatives based on the errors you have seen."

  jq -n --arg msg "$MSG" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUseFailure",
      additionalContext: $msg
    }
  }'
fi

exit 0
