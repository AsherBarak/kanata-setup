
# Kanata-Setup

Cross‑platform home‑row‑mods keyboard layout for macOS **and** Windows, plus one‑line installers.

## Features

* Identical keymap on both operating systems  
* Home‑row tap/hold: **A‑S‑D‑F / J‑K‑L‑;** become Ctrl‑Alt‑Super‑Shift  
* **Space** held = arrow/navigation layer (IJKL arrows, O/U Home/End)  
* **CapsLock** toggles the layout on/off (fallback if tray isn’t running)  
* UI tray/menu‑bar lets non‑technical users switch between layouts

## Quick install

### macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/USERNAME/kanata-setup/main/install.sh)"
```

### Windows 10/11 (PowerShell)

```powershell
irm https://raw.githubusercontent.com/USERNAME/kanata-setup/main/install.ps1 | iex
```

Replace **USERNAME** with your GitHub account after you upload this repo.

## Folder structure

```
kanata-setup/
├─ configs/
│   ├─ mods.kbd   ← the layout
│   └─ bare.kbd   ← pass‑through
├─ install.sh     ← mac installer
└─ install.ps1    ← Windows installer
```

## Switching layouts

* Use the tray/menu‑bar icon to choose `mods.kbd` or `bare.kbd`
* Or press **CapsLock** to toggle the mapping globally
