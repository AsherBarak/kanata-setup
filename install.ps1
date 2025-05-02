
param(
    [string]$RepoUrl = "https://github.com/AsherBarak/kanata-setup.git"
)

Write-Host "[+] Ensuring Scoop..."
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    iex "&{(New-Object Net.WebClient).DownloadString('https://get.scoop.sh')}"
}
scoop install git
scoop bucket add extras
scoop install kanata

$dest = "$env:USERPROFILE\kanata-setup"
if (Test-Path $dest) {
    git -C $dest pull --quiet
} else {
    git clone --depth=1 $RepoUrl $dest
}

$cfgDir = "$env:USERPROFILE\kanata"
mkdir $cfgDir -Force | Out-Null
copy-item "$dest\configs\*.kbd" $cfgDir -Force

$startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\kanata-startup.bat"
"@echo off
start kanata.exe --cfg ""%USERPROFILE%\kanata\mods.kbd""
" | set-content $startup -Encoding ASCII

Write-Host "[✓] Kanata installed. Log off and back on, or run '$startup' to start now."
