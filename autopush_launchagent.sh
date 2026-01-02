#!/bin/zsh
set -eu

SCRIPT_DIR="$(cd -- "$(dirname "${0:A}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/config.env}"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

REPO="${REPO_DIR:-$SCRIPT_DIR}"
AUTOPUSH_SCRIPT_PATH="${AUTOPUSH_SCRIPT:-$REPO/autopush.sh}"
PATH_VALUE="${AUTOPUSH_PATH:-/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin}"
STDOUT_LOG="${AUTOPUSH_STDOUT_LOG:-$REPO/autopush.out.log}"
STDERR_LOG="${AUTOPUSH_STDERR_LOG:-$REPO/autopush.err.log}"
LABEL="${LAUNCH_AGENT_LABEL:-com.okuda.dictionaryrecorder.autopush}"
PLIST_PATH="${LAUNCH_AGENT_PATH:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
START_HOUR="${LAUNCH_START_HOUR:-12}"
START_MINUTE="${LAUNCH_START_MINUTE:-0}"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$AUTOPUSH_SCRIPT_PATH</string>
  </array>

  <key>WorkingDirectory</key>
  <string>$REPO</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$PATH_VALUE</string>
  </dict>

  <key>StandardOutPath</key>
  <string>$STDOUT_LOG</string>
  <key>StandardErrorPath</key>
  <string>$STDERR_LOG</string>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>$START_HOUR</integer>
    <key>Minute</key><integer>$START_MINUTE</integer>
  </dict>

  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

plutil -lint "$PLIST_PATH"
launchctl bootout gui/$(id -u) "$PLIST_PATH" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST_PATH"
launchctl enable gui/$(id -u)/"$LABEL"
