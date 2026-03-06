# ── Hook Setup ────────────────────────────────────────────────────────────────

# Setup Claude Code hooks (project-local)
# - Notification + Stop: native OS notifications
# - PostToolUseFailure: tool failure guard (asks user after 4+ consecutive failures)
setup_notifications() {
  local scripts_dir=".claude/scripts"
  local settings_file=".claude/settings.json"

  # Create scripts directory
  mkdir -p "$scripts_dir"

  # Download and install scripts into project
  download "${BASE_URL}/scripts/notify.sh" "$scripts_dir/notify.sh"
  chmod +x "$scripts_dir/notify.sh"
  download "${BASE_URL}/scripts/tool-failure-guard.sh" "$scripts_dir/tool-failure-guard.sh"
  chmod +x "$scripts_dir/tool-failure-guard.sh"

  # Warn if global hooks exist from a previous dotcontext version
  if [ -f "$HOME/.claude/settings.json" ] && grep -q "notify.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
    print_yellow "Global notification hooks detected in ~/.claude/settings.json"
    print_yellow "dotcontext now configures hooks per-project. You can remove the global hooks manually."
  fi

  # Create or update project-local settings.json with hooks
  local notification_hook='{
    "matcher": "",
    "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh '\''Claude Code'\'' '\''Needs your attention'\'' question"}]
  }'
  local stop_hook='{
    "matcher": "",
    "hooks": [{"type": "command", "command": ".claude/scripts/notify.sh '\''Claude Code'\'' '\''Task completed'\'' success"}]
  }'
  local failure_guard_hook='{
    "matcher": "",
    "hooks": [{"type": "command", "command": ".claude/scripts/tool-failure-guard.sh"}]
  }'

  if [ ! -f "$settings_file" ]; then
    cat > "$settings_file" << 'SETTINGS_EOF'
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
SETTINGS_EOF
    print_gray "Hooks configured in .claude/settings.json"
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
          print_gray "Notification hooks added to .claude/settings.json"
        else
          rm -f "$temp_file"
        fi
      else
        print_yellow "Install jq to auto-configure hooks, or add manually"
      fi
    fi

    # Add failure guard if not already present
    if ! grep -q "tool-failure-guard" "$settings_file" 2>/dev/null; then
      if command -v jq &>/dev/null; then
        local temp_file=$(mktemp)
        jq --argjson guard "$failure_guard_hook" '
          .hooks.PostToolUseFailure = ((.hooks.PostToolUseFailure // []) + [$guard])
        ' "$settings_file" > "$temp_file" 2>/dev/null
        if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
          mv "$temp_file" "$settings_file"
          print_gray "Tool failure guard hook added to .claude/settings.json"
        else
          rm -f "$temp_file"
        fi
      fi
    fi
  fi
}
