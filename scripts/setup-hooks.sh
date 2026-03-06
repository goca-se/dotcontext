#!/bin/bash
# Setup Claude Code hooks (project-local)
# - Notification + Stop: native OS notifications
# - PostToolUseFailure: tool failure guard

SCRIPTS_DIR=".claude/scripts"
SETTINGS_FILE=".claude/settings.json"

# Ensure directories exist
mkdir -p "$SCRIPTS_DIR"

# Copy scripts into project
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/notify.sh" "$SCRIPTS_DIR/notify.sh"
chmod +x "$SCRIPTS_DIR/notify.sh"
cp "$SCRIPT_DIR/tool-failure-guard.sh" "$SCRIPTS_DIR/tool-failure-guard.sh"
chmod +x "$SCRIPTS_DIR/tool-failure-guard.sh"

# Warn about legacy global hooks
if [ -f "$HOME/.claude/settings.json" ] && grep -q "notify.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
  echo "Warning: Global notification hooks detected in ~/.claude/settings.json"
  echo "dotcontext now configures hooks per-project. You can remove the global hooks manually."
  echo ""
fi

# Create or update project-local settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh 'Claude Code' 'Needs your attention' question"}]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh 'Claude Code' 'Task completed' success"}]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/tool-failure-guard.sh"}]
      }
    ]
  }
}
EOF
  echo "Created $SETTINGS_FILE with hooks"
else
  if command -v jq &>/dev/null; then
    TEMP_FILE=$(mktemp)

    jq '
      .hooks.Notification = ((.hooks.Notification // []) + [{
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh '\''Claude Code'\'' '\''Needs your attention'\'' question"}]
      }] | unique_by(.hooks[0].command)) |
      .hooks.Stop = ((.hooks.Stop // []) + [{
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh '\''Claude Code'\'' '\''Task completed'\'' success"}]
      }] | unique_by(.hooks[0].command)) |
      .hooks.PostToolUseFailure = ((.hooks.PostToolUseFailure // []) + [{
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/tool-failure-guard.sh"}]
      }] | unique_by(.hooks[0].command))
    ' "$SETTINGS_FILE" > "$TEMP_FILE" 2>/dev/null

    if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
      mv "$TEMP_FILE" "$SETTINGS_FILE"
      echo "Updated $SETTINGS_FILE with hooks"
    else
      rm -f "$TEMP_FILE"
      echo "Warning: Could not update settings.json automatically"
      echo "Please add hooks manually. See documentation."
    fi
  else
    echo "Warning: jq not installed. Cannot merge settings automatically."
    echo ""
    echo "Please add these hooks to $SETTINGS_FILE manually:"
    echo ""
    cat << 'EOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh 'Claude Code' 'Needs your attention' question"}]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh 'Claude Code' 'Task completed' success"}]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": ".claude/scripts/tool-failure-guard.sh"}]
      }
    ]
  }
}
EOF
  fi
fi

echo ""
echo "Hooks installed in $SCRIPTS_DIR:"
echo "  notify.sh             — OS notifications"
echo "  tool-failure-guard.sh — stops retrying after 4+ failures"
echo ""
echo "Test notification with:"
echo "  $SCRIPTS_DIR/notify.sh 'Test' 'Hello World' default"
