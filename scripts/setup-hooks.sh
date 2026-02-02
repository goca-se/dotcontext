#!/bin/bash
# Setup Claude Code hooks for notifications
# This script merges notification hooks into existing settings

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
NOTIFY_SCRIPT="$CLAUDE_DIR/scripts/notify.sh"

# Ensure directories exist
mkdir -p "$CLAUDE_DIR/scripts"

# Copy notify script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/notify.sh" "$NOTIFY_SCRIPT"
chmod +x "$NOTIFY_SCRIPT"

# Create or update settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  # Create new settings file
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "command": "~/.claude/scripts/notify.sh 'Claude Code' 'Needs your attention' question"
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "command": "~/.claude/scripts/notify.sh 'Claude Code' 'Task completed' success"
      }
    ]
  }
}
EOF
  echo "Created $SETTINGS_FILE with notification hooks"
else
  # Check if jq is available for proper JSON merging
  if command -v jq &>/dev/null; then
    # Merge hooks into existing settings
    TEMP_FILE=$(mktemp)

    jq '
      .hooks.Notification = ((.hooks.Notification // []) + [{
        "matcher": "",
        "command": "~/.claude/scripts/notify.sh '\''Claude Code'\'' '\''Needs your attention'\'' question"
      }] | unique_by(.command)) |
      .hooks.Stop = ((.hooks.Stop // []) + [{
        "matcher": "",
        "command": "~/.claude/scripts/notify.sh '\''Claude Code'\'' '\''Task completed'\'' success"
      }] | unique_by(.command))
    ' "$SETTINGS_FILE" > "$TEMP_FILE" 2>/dev/null

    if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
      mv "$TEMP_FILE" "$SETTINGS_FILE"
      echo "Updated $SETTINGS_FILE with notification hooks"
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
        "command": "~/.claude/scripts/notify.sh 'Claude Code' 'Needs your attention' question"
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "command": "~/.claude/scripts/notify.sh 'Claude Code' 'Task completed' success"
      }
    ]
  }
}
EOF
  fi
fi

echo ""
echo "Notification script installed at: $NOTIFY_SCRIPT"
echo ""
echo "Test it with:"
echo "  $NOTIFY_SCRIPT 'Test' 'Hello World' default"
