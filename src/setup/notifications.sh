# ── Notification Setup ────────────────────────────────────────────────────────

# Setup notifications for Claude Code
setup_notifications() {
  local claude_dir="$HOME/.claude"
  local scripts_dir="$claude_dir/scripts"
  local settings_file="$claude_dir/settings.json"
  local notify_script="$scripts_dir/notify.sh"

  # Create scripts directory
  mkdir -p "$scripts_dir"

  # Download and install notify script
  download "${BASE_URL}/scripts/notify.sh" "$notify_script"
  chmod +x "$notify_script"

  # Create or update settings.json with hooks (matcher is string regex, empty = match all)
  local notification_hook='{
    "matcher": "",
    "hooks": [{"type": "command", "command": "~/.claude/scripts/notify.sh '\''Claude Code'\'' '\''Needs your attention'\'' question"}]
  }'
  local stop_hook='{
    "matcher": "",
    "hooks": [{"type": "command", "command": "~/.claude/scripts/notify.sh '\''Claude Code'\'' '\''Task completed'\'' success"}]
  }'

  if [ ! -f "$settings_file" ]; then
    cat > "$settings_file" << 'SETTINGS_EOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "~/.claude/scripts/notify.sh 'Claude Code' 'Needs your attention' question"}]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "~/.claude/scripts/notify.sh 'Claude Code' 'Task completed' success"}]
      }
    ]
  }
}
SETTINGS_EOF
    print_gray "Notifications configured in ~/.claude/settings.json"
  else
    # Check if hooks already configured
    if ! grep -q "notify.sh" "$settings_file" 2>/dev/null; then
      if command -v jq &>/dev/null; then
        local temp_file=$(mktemp)
        jq --argjson notif "$notification_hook" --argjson stop "$stop_hook" '
          .hooks.Notification = ((.hooks.Notification // []) + [$notif]) |
          .hooks.Stop = ((.hooks.Stop // []) + [$stop])
        ' "$settings_file" > "$temp_file" 2>/dev/null
        if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
          mv "$temp_file" "$settings_file"
          print_gray "Notification hooks added to ~/.claude/settings.json"
        else
          rm -f "$temp_file"
        fi
      else
        print_yellow "Install jq to auto-configure notification hooks, or add manually"
      fi
    fi
  fi
}
