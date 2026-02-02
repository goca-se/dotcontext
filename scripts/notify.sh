#!/bin/bash
# Cross-platform notification script for Claude Code
# Supports macOS, Linux, and Windows (WSL/Git Bash)

TITLE="${1:-Claude Code}"
MESSAGE="${2:-Task completed}"
SOUND="${3:-default}"

# Detect OS
detect_os() {
  case "$(uname -s)" in
    Darwin*) echo "macos" ;;
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

OS=$(detect_os)

# Get macOS sound name
get_macos_sound() {
  case "$SOUND" in
    success) echo "Funk" ;;
    error) echo "Basso" ;;
    question) echo "Purr" ;;
    *) echo "Glass" ;;
  esac
}

# Show notification based on OS
show_notification() {
  case "$OS" in
    macos)
      local sound_name=$(get_macos_sound)
      osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$sound_name\"" 2>/dev/null
      ;;
    linux)
      # Play sound
      local sound_file="/usr/share/sounds/freedesktop/stereo/complete.oga"
      if [ "$SOUND" = "error" ]; then
        sound_file="/usr/share/sounds/freedesktop/stereo/dialog-error.oga"
      elif [ "$SOUND" = "question" ]; then
        sound_file="/usr/share/sounds/freedesktop/stereo/dialog-question.oga"
      fi

      if command -v paplay &>/dev/null; then
        paplay "$sound_file" 2>/dev/null &
      elif command -v aplay &>/dev/null; then
        aplay "$sound_file" 2>/dev/null &
      fi

      # Show notification
      if command -v notify-send &>/dev/null; then
        local icon="dialog-information"
        if [ "$SOUND" = "error" ]; then
          icon="dialog-error"
        elif [ "$SOUND" = "question" ]; then
          icon="dialog-question"
        fi
        notify-send -i "$icon" "$TITLE" "$MESSAGE" 2>/dev/null
      fi
      ;;
    wsl|windows)
      # Play sound
      powershell.exe -Command "[System.Media.SystemSounds]::Asterisk.Play()" 2>/dev/null &

      # Show notification
      powershell.exe -Command "
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        \$template = @\"
        <toast>
          <visual>
            <binding template=\"ToastText02\">
              <text id=\"1\">$TITLE</text>
              <text id=\"2\">$MESSAGE</text>
            </binding>
          </visual>
        </toast>
\"@
        \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        \$xml.LoadXml(\$template)
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
      " 2>/dev/null &
      ;;
  esac
}

# Execute
show_notification
