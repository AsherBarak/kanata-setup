# Kanata-Setup

Cross‑platform home‑row‑mods keyboard layout for macOS **and** Windows, plus one‑line installers.

## Features

* Identical keymap on both operating systems  
* Home‑row tap/hold: **A‑S‑D‑F / J‑K‑L‑;** become Shift‑Ctrl‑Alt‑Super  
* **Space** held = arrow/navigation layer (HJKL arrows, etc.)  
* Chords: **W+E** = Esc, **I+O** = Backspace, **X+C** = Tab, **,+.** = Enter

## Quick Install

### macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AsherBarak/kanata-setup/main/install.sh)"
```

**After running the script, you must:**
1. Open **System Settings → Privacy & Security → Input Monitoring**
2. Click **+** and add `/Applications/Kanata.app`
3. Enable the toggle
4. **Restart your Mac**

### Windows 10/11 (PowerShell)

```powershell
irm https://raw.githubusercontent.com/AsherBarak/kanata-setup/main/install.ps1 | iex
```

## Folder Structure

```
kanata-setup/
├─ configs/
│   ├─ asher.kbd  ← full layout with home-row mods
│   ├─ mods.kbd   ← alternative layout
│   └─ bare.kbd   ← pass‑through (no remapping)
├─ install.sh     ← macOS installer
└─ install.ps1    ← Windows installer
```

## Using a Different Config

```bash
# Use a specific config file
curl -fsSL https://raw.githubusercontent.com/AsherBarak/kanata-setup/main/install.sh | bash -s -- --config mods.kbd
```

## Managing Kanata (macOS)

### View logs
```bash
tail -f /tmp/kanata.stdout.log
tail -f /tmp/kanata.stderr.log
```

### Restart kanata (after config changes)
```bash
sudo launchctl unload /Library/LaunchDaemons/com.asbr.kanata.plist
sudo launchctl load /Library/LaunchDaemons/com.asbr.kanata.plist
```

### Stop kanata
```bash
sudo launchctl unload /Library/LaunchDaemons/com.asbr.kanata.plist
```

### Check status
```bash
ps aux | grep kanata
sudo launchctl list | grep kanata
```

## Uninstall (macOS)

```bash
sudo launchctl unload /Library/LaunchDaemons/com.asbr.kanata.plist
sudo rm /Library/LaunchDaemons/com.asbr.kanata.plist
rm -rf /Applications/Kanata.app
rm -rf ~/.kanata-setup
rm -rf ~/.config/kanata
# Optional: brew uninstall kanata
```

## Troubleshooting

### "IOHIDDeviceOpen error: not permitted"

Kanata cannot access your keyboard. Fix:
1. Remove Kanata from Input Monitoring
2. Re-add `/Applications/Kanata.app`
3. **Restart your Mac** (required for permission to take effect)

### Kanata not starting at boot

```bash
# Check daemon status
sudo launchctl list | grep kanata

# Reload manually
sudo launchctl unload /Library/LaunchDaemons/com.asbr.kanata.plist
sudo launchctl load /Library/LaunchDaemons/com.asbr.kanata.plist
```

### Config file errors

```bash
# Validate your config
/Applications/Kanata.app/Contents/MacOS/Kanata --check --cfg ~/.config/kanata/asher.kbd
```

## How It Works (macOS)

1. **Karabiner-Elements** provides the virtual HID driver (required for kanata to create virtual keyboard events)
2. **Kanata.app** is a wrapper around the kanata binary (required for Input Monitoring permission)
3. **LaunchDaemon** runs kanata as root at startup (required for keyboard access)
4. **Input Monitoring** permission allows kanata to read keyboard input
