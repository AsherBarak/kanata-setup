
#!/usr/bin/env bash
set -euo pipefail

REPO_URL=${REPO_URL:-"https://github.com/AsherBarak/kanata-setup.git"}

echo "[+] Ensuring Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "[+] Installing Kanata..."
brew install kanata

echo "[+] Cloning or updating repo..."
DEST="$HOME/.kanata-setup"
if [ -d "$DEST" ]; then
  git -C "$DEST" pull --quiet
else
  git clone --depth=1 "$REPO_URL" "$DEST"
fi

mkdir -p "$HOME/.config/kanata"
cp "$DEST/configs/"*.kbd "$HOME/.config/kanata/"

PLIST="$HOME/Library/LaunchAgents/com.${USER}.kanata.plist"
echo "[+] Writing LaunchAgent $PLIST"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>          <string>com.${USER}.kanata</string>
  <key>ProgramArguments</key>
    <array>
      <string>$(which kanata)</string>
      <string>--cfg</string>
      <string>$HOME/.config/kanata/asher.kbd</string>
      <string>--reload-on-sighup</string>
    </array>
  <key>RunAtLoad</key>      <true/>
</dict>
</plist>
EOF

launchctl unload "$PLIST" >/dev/null 2>&1 || true
launchctl load "$PLIST"

echo "[✓] Kanata installed and running."
echo "    Use the menu-bar icon to switch between mods.kbd and bare.kbd."
