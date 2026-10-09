#!/usr/bin/env bash
#
# Kanata macOS Setup Script
# Installs and configures Kanata to run at startup with proper Input Monitoring support
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AsherBarak/kanata-setup/main/install.sh | bash
#
# Or with a specific config:
#   curl -fsSL ... | bash -s -- --config mods.kbd
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_URL="${REPO_URL:-https://github.com/AsherBarak/kanata-setup.git}"
DEST="${KANATA_SETUP_DIR:-$HOME/.kanata-setup}"   # set KANATA_SETUP_DIR to use an existing clone
CONFIG_NAME="asher.kbd"
KANATA_APP="/Applications/Kanata.app"
LAUNCH_DAEMON="/Library/LaunchDaemons/com.asbr.kanata.plist"
DRIVER_LAUNCH_DAEMON="/Library/LaunchDaemons/org.pqrs.karabiner-vhiddaemon.plist"
DRIVER_VERSION="6.2.0"   # supported by kanata 1.12 (see Step 2)

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --config|-c)
      CONFIG_NAME="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

CONFIG_FILE="$HOME/.config/kanata/$CONFIG_NAME"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       Kanata macOS Setup Script       ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script only works on macOS${NC}"
    exit 1
fi

# Step 1: Ensure Homebrew
echo -e "${YELLOW}Step 1: Checking Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}✓ Homebrew is installed${NC}"
fi

# Step 2: Install the Karabiner VirtualHIDDevice driver (kanata sends keys through it)
#
# Use the standalone driver, not the Karabiner-Elements app:
#  - Karabiner-Elements ships a newer driver than kanata supports, and kanata
#    then cannot connect to it ("output backend unavailable").
#  - Karabiner-Elements' own service takes the keyboard exclusively, so kanata
#    cannot open it ("exclusive access and device already open").
# Each kanata release names its supported driver version under "macOS" in its
# release notes. Change DRIVER_VERSION when kanata changes it.
echo ""
echo -e "${YELLOW}Step 2: Checking Karabiner VirtualHIDDevice driver v${DRIVER_VERSION}...${NC}"
DRIVER_DIR="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice"
DRIVER_DAEMON="$DRIVER_DIR/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
DRIVER_MANAGER="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"

if [[ -d "/Applications/Karabiner-Elements.app" ]]; then
    echo -e "${RED}Karabiner-Elements is installed. It conflicts with kanata.${NC}"
    echo "Uninstall it first:  brew uninstall --cask karabiner-elements"
    exit 1
fi

installed=$(defaults read "$DRIVER_DIR/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || true)
if [[ "$installed" != "$DRIVER_VERSION" ]]; then
    pkg="/tmp/Karabiner-DriverKit-VirtualHIDDevice-${DRIVER_VERSION}.pkg"
    curl -fsSL -o "$pkg" "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${DRIVER_VERSION}/Karabiner-DriverKit-VirtualHIDDevice-${DRIVER_VERSION}.pkg"
    pkgutil --check-signature "$pkg" | grep -q "Developer ID Installer: Fumihiko Takayama (G43BCU2T37)" || {
        echo -e "${RED}Error: driver package signature is not the expected one${NC}"; exit 1; }
    sudo installer -pkg "$pkg" -target /
    sudo "$DRIVER_MANAGER" activate

    echo ""
    echo -e "${YELLOW}Allow the driver:${NC} System Settings -> General -> Login Items & Extensions"
    echo "  -> Driver Extensions -> enable .Karabiner-VirtualHIDDevice-Manager"
    read -r -p "Press Enter after you allow it, or Ctrl+C to exit..." < /dev/tty || true
fi

# The driver daemon must run as root at startup. Karabiner-Elements used to start it.
sudo tee "$DRIVER_LAUNCH_DAEMON" > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.pqrs.karabiner-vhiddaemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>$DRIVER_DAEMON</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF
sudo chown root:wheel "$DRIVER_LAUNCH_DAEMON"
sudo chmod 644 "$DRIVER_LAUNCH_DAEMON"
sudo launchctl bootout system "$DRIVER_LAUNCH_DAEMON" 2>/dev/null || true
sudo launchctl bootstrap system "$DRIVER_LAUNCH_DAEMON"
echo -e "${GREEN}✓ Karabiner VirtualHIDDevice driver v${DRIVER_VERSION} is installed and its daemon runs${NC}"

# Step 3: Install Kanata
echo ""
echo -e "${YELLOW}Step 3: Installing Kanata...${NC}"
if ! command -v kanata &> /dev/null; then
    brew install kanata
else
    echo -e "${GREEN}✓ Kanata is already installed${NC}"
fi

KANATA_BIN=$(which kanata)
echo "Kanata binary: $KANATA_BIN"

# Step 4: Clone/update repo and link ~/.config/kanata to its configs/
# The link makes a repo edit the live config: tap Caps Lock (lrld) to reload it.
echo ""
echo -e "${YELLOW}Step 4: Setting up configuration files...${NC}"
if [[ -d "$DEST" ]]; then
    echo "Updating existing repo..."
    git -C "$DEST" pull --quiet
else
    echo "Cloning configuration repo..."
    git clone "$REPO_URL" "$DEST"
fi

mkdir -p "$HOME/.config"
if [[ -d "$HOME/.config/kanata" && ! -L "$HOME/.config/kanata" ]]; then
    backup="$HOME/.config/kanata.backup-$(date +%Y%m%d%H%M%S)"
    mv "$HOME/.config/kanata" "$backup"
    echo "Moved the old ~/.config/kanata to $backup"
fi
ln -sfn "$DEST/configs" "$HOME/.config/kanata"
echo -e "${GREEN}✓ Linked ~/.config/kanata to $DEST/configs${NC}"

# Validate config
echo "Validating configuration..."
if ! "$KANATA_BIN" --check --cfg "$CONFIG_FILE"; then
    echo -e "${RED}Error: Config file is invalid: $CONFIG_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Config is valid${NC}"

# Step 5: Create Kanata.app wrapper (required for Input Monitoring permission)
echo ""
echo -e "${YELLOW}Step 5: Creating Kanata.app wrapper...${NC}"

# Remove old app if exists
rm -rf "$KANATA_APP"

# Create app bundle structure
mkdir -p "$KANATA_APP/Contents/MacOS"

# Copy the actual kanata binary (not a wrapper script - macOS tracks the real binary for permissions)
cp "$KANATA_BIN" "$KANATA_APP/Contents/MacOS/Kanata"
chmod +x "$KANATA_APP/Contents/MacOS/Kanata"

# Create Info.plist
cat > "$KANATA_APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Kanata</string>
    <key>CFBundleIdentifier</key>
    <string>com.asbr.kanata</string>
    <key>CFBundleName</key>
    <string>Kanata</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ Created $KANATA_APP${NC}"

# Step 6: Create LaunchDaemon (requires sudo - runs as root for keyboard access)
echo ""
echo -e "${YELLOW}Step 6: Creating LaunchDaemon (requires sudo)...${NC}"

# Unload existing daemon if present
sudo launchctl unload "$LAUNCH_DAEMON" 2>/dev/null || true

sudo tee "$LAUNCH_DAEMON" > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.asbr.kanata</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Applications/Kanata.app/Contents/MacOS/Kanata</string>
    <string>--cfg</string>
    <string>$CONFIG_FILE</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/kanata.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/kanata.stderr.log</string>
</dict>
</plist>
EOF

# Set correct ownership and permissions
sudo chown root:wheel "$LAUNCH_DAEMON"
sudo chmod 644 "$LAUNCH_DAEMON"

echo -e "${GREEN}✓ Created $LAUNCH_DAEMON${NC}"

# Step 7: Load the daemon
echo ""
echo -e "${YELLOW}Step 7: Loading LaunchDaemon...${NC}"
sudo launchctl load "$LAUNCH_DAEMON"
echo -e "${GREEN}✓ LaunchDaemon loaded${NC}"

# Step 8: Keyboard watcher (kanata grabs only keyboards connected at start)
echo ""
echo -e "${YELLOW}Step 8: Installing the keyboard watcher...${NC}"
"$DEST/macos/install-watch.sh"

# Final instructions
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}       Setup Almost Complete!          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}MANUAL STEP REQUIRED:${NC}"
echo ""
echo "Kanata needs TWO permissions. Do both:"
echo ""
echo "1. System Settings → Privacy & Security → Input Monitoring"
echo "   Click '+', select /Applications/Kanata.app, enable the toggle"
echo ""
echo "2. System Settings → Privacy & Security → Accessibility"
echo "   Click '+', select /Applications/Kanata.app, enable the toggle"
echo ""
echo -e "${RED}3. RESTART YOUR MAC for the permissions to take effect${NC}"
echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo "After restart, verify with:"
echo "  ps aux | grep kanata"
echo "  tail /tmp/kanata.stdout.log"
echo ""
echo "If you see 'IOHIDDeviceOpen error: not permitted' in the logs,"
echo "the Input Monitoring permission is not properly set."
echo ""
echo "Logs are at:"
echo "  /tmp/kanata.stdout.log"
echo "  /tmp/kanata.stderr.log"
echo -e "${BLUE}========================================${NC}"
