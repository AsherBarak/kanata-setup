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
DEST="$HOME/.kanata-setup"
CONFIG_NAME="asher.kbd"
KANATA_APP="/Applications/Kanata.app"
LAUNCH_DAEMON="/Library/LaunchDaemons/com.asbr.kanata.plist"

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

# Step 2: Install Karabiner-Elements (required for virtual HID driver)
echo ""
echo -e "${YELLOW}Step 2: Checking Karabiner DriverKit...${NC}"
if [[ ! -d "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice" ]]; then
    echo "Installing Karabiner-Elements (required for virtual HID driver)..."
    brew install --cask karabiner-elements
    
    echo -e "${YELLOW}Opening Karabiner-Elements to activate the driver...${NC}"
    open "/Applications/Karabiner-Elements.app"
    
    echo ""
    echo -e "${YELLOW}Please:${NC}"
    echo "  1. Allow the system extension when prompted"
    echo "  2. Grant Input Monitoring permission when prompted"
    echo "  3. Re-run this script after Karabiner is set up"
    echo ""
    read -p "Press Enter once Karabiner-Elements is set up, or Ctrl+C to exit..."
fi
echo -e "${GREEN}✓ Karabiner DriverKit is installed${NC}"

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

# Step 4: Clone/update repo and copy configs
echo ""
echo -e "${YELLOW}Step 4: Setting up configuration files...${NC}"
if [[ -d "$DEST" ]]; then
    echo "Updating existing repo..."
    git -C "$DEST" pull --quiet
else
    echo "Cloning configuration repo..."
    git clone --depth=1 "$REPO_URL" "$DEST"
fi

mkdir -p "$HOME/.config/kanata"
cp "$DEST/configs/"*.kbd "$HOME/.config/kanata/"
echo -e "${GREEN}✓ Copied config files to ~/.config/kanata/${NC}"

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

# Final instructions
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}       Setup Almost Complete!          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}MANUAL STEP REQUIRED:${NC}"
echo ""
echo "1. Open System Settings → Privacy & Security → Input Monitoring"
echo ""
echo "2. Click the '+' button"
echo ""
echo "3. Navigate to /Applications and select 'Kanata.app'"
echo ""
echo "4. Enable the toggle next to Kanata"
echo ""
echo -e "${RED}5. RESTART YOUR MAC for the permission to take effect${NC}"
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
