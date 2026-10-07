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

The script installs the Karabiner VirtualHIDDevice driver (standalone, not the
Karabiner-Elements app) and asks you to allow it in **System Settings → General
→ Login Items & Extensions → Driver Extensions**.

**After running the script, you must:**
1. Open **System Settings → Privacy & Security → Input Monitoring**, click **+**,
   add `/Applications/Kanata.app`, and enable the toggle
2. Open **System Settings → Privacy & Security → Accessibility**, click **+**,
   add `/Applications/Kanata.app`, and enable the toggle
3. **Restart your Mac**

Do not install Karabiner-Elements. It ships a newer driver than kanata supports,
and its own service takes the keyboard, so kanata cannot use it.

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
sudo launchctl bootout system /Library/LaunchDaemons/org.pqrs.karabiner-vhiddaemon.plist
sudo rm /Library/LaunchDaemons/org.pqrs.karabiner-vhiddaemon.plist
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

### "kanata needs macOS Accessibility permission"

Add `/Applications/Kanata.app` in **Privacy & Security → Accessibility** too.
Kanata needs both Input Monitoring and Accessibility.

### "output backend unavailable" or "exclusive access and device already open"

The driver is the wrong version, or Karabiner-Elements is installed. Uninstall
Karabiner-Elements (`brew uninstall --cask karabiner-elements`), restart, and run
the script again. It installs the driver version that kanata supports
(`DRIVER_VERSION` in `install.sh`).

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

1. **Karabiner VirtualHIDDevice driver** (standalone, at the version kanata supports) provides the virtual keyboard that kanata sends keys through. A second LaunchDaemon, `org.pqrs.karabiner-vhiddaemon`, starts its daemon at boot
2. **Kanata.app** is a wrapper around the kanata binary (required for Input Monitoring permission)
3. **LaunchDaemon** runs kanata as root at startup (required for keyboard access)
4. **Input Monitoring** and **Accessibility** permissions allow kanata to read keyboard input
