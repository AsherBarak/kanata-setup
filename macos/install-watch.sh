#!/usr/bin/env bash
#
# Install the keyboard watcher (kanata-watch.sh) as a root LaunchDaemon.
# install.sh runs this. You can also run it alone:  ./macos/install-watch.sh
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/kanata-watch.sh"
# A root daemon must not run a script that a normal user can edit,
# so the script is copied to a root-owned folder.
DIR="/Library/Application Support/kanata-setup"
SCRIPT="$DIR/kanata-watch.sh"
PLIST="/Library/LaunchDaemons/com.asbr.kanata-watch.plist"

sudo mkdir -p "$DIR"
sudo install -o root -g wheel -m 755 "$SRC" "$SCRIPT"

sudo tee "$PLIST" > /dev/null << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.asbr.kanata-watch</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SCRIPT</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/kanata-watch.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/kanata-watch.log</string>
</dict>
</plist>
PLIST_EOF
sudo chown root:wheel "$PLIST"
sudo chmod 644 "$PLIST"
sudo launchctl bootout system "$PLIST" 2>/dev/null || true
sudo launchctl bootstrap system "$PLIST"
echo "✓ Keyboard watcher installed. Log: /tmp/kanata-watch.log"
