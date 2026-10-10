# Kanata-Setup

Cross‑platform home‑row‑mods keyboard layout for macOS **and** Windows, plus one‑line installers.

## Features

* Identical keymap on both operating systems  
* Home‑row tap/hold: **A‑S‑D‑F / J‑K‑L‑;** become Shift‑Ctrl‑Alt‑Super  
* Fast typing does not trigger mods or chords: a key pressed less than 200 ms
  after another key types its letter at once (`tap-hold-require-prior-idle`,
  `chords-v2-min-idle`). A home-row key becomes a mod only after a 200 ms hold  
* **Space** held = navigation layer. Keys around J go left, keys around L go right:
  * I J K L = arrows
  * U / O = Cmd+Left / Cmd+Right: left / right edge of the line (in Hebrew, U goes to the end)
  * M / . = Ctrl+Shift+Tab / Ctrl+Tab: previous / next tab
  * H / ; = Ctrl+Option+Left / Right: window to the left / right half (Rectangle)  
* A keyboard that you connect after kanata starts gets the layout too
  (macOS keyboard watcher, see below)  
* Chords (press both keys within 50 ms): **W+E** = Esc, **I+O** = Backspace, **X+C** = Tab, **,+.** = Backspace

## Rectangle (macOS)

Space+H and Space+; send the default Rectangle shortcuts for the left and right
half. Install Rectangle (`brew install --cask rectangle`), open it, select the
**Recommended** shortcuts, and give it Accessibility permission.

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
│   └─ asher.kbd  ← full layout with home-row mods
├─ macos/
│   ├─ kanata-watch.sh   ← restarts kanata when a keyboard connects
│   └─ install-watch.sh  ← installs the watcher LaunchDaemon
├─ install.sh     ← macOS installer
└─ install.ps1    ← Windows installer
```

## Editing the Config (macOS)

`~/.config/kanata` is a link to the `configs/` folder of the repo clone. Edit a
file in the repo, then **tap Caps Lock** (`lrld`) to reload it. No restart is
necessary.

The installer clones to `~/.kanata-setup`. To use a clone that you already have:

```bash
KANATA_SETUP_DIR=~/Dev/Personal/kanata-setup ./install.sh
```

## Keyboard Watcher (macOS)

kanata on macOS grabs only the keyboards that are connected when it starts.
The watcher LaunchDaemon `com.asbr.kanata-watch` reads the keyboard list every
3 seconds. When a new keyboard appears, it restarts kanata, and the new keyboard
gets the layout in about 5 seconds. A keyboard that goes away needs no restart.
When the watcher starts, it also restarts kanata one time, because kanata can
have started before a keyboard connected.

`install.sh` installs it. To install or update only the watcher:

```bash
./macos/install-watch.sh
```

Its log is `/tmp/kanata-watch.log`. The daemon runs a root-owned copy of the
script in `/Library/Application Support/kanata-setup/`, so run
`install-watch.sh` again after you change `kanata-watch.sh`.

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
sudo launchctl bootout system /Library/LaunchDaemons/com.asbr.kanata-watch.plist
sudo rm /Library/LaunchDaemons/com.asbr.kanata-watch.plist
sudo rm -rf "/Library/Application Support/kanata-setup"
sudo launchctl bootout system /Library/LaunchDaemons/org.pqrs.karabiner-vhiddaemon.plist
sudo rm /Library/LaunchDaemons/org.pqrs.karabiner-vhiddaemon.plist
rm -rf /Applications/Kanata.app
rm ~/.config/kanata   # the link
rm -rf ~/.kanata-setup
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
