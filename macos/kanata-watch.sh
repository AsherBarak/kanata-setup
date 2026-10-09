#!/bin/bash
#
# Restart kanata when a new keyboard connects.
#
# kanata on macOS grabs only the keyboards that are connected when it starts.
# This script runs as a root LaunchDaemon (com.asbr.kanata-watch). Every
# INTERVAL seconds it reads the keyboard list. When a keyboard appears that
# was not there before, it restarts the kanata LaunchDaemon. A keyboard that
# goes away needs no restart.

INTERVAL=3
KANATA_JOB="system/com.asbr.kanata"

# One line per keyboard HID device: "<RegistryID> <rest of the hidutil line>".
# The Karabiner virtual keyboard is kanata's own output, so it is not included.
keyboards() {
  hidutil list --matching '{"PrimaryUsagePage":1,"PrimaryUsage":6}' 2>/dev/null |
    awk '/^Devices:/ { d = 1; next }
         d && /^0x/ && !/Karabiner/ { print $6, $0 }' |
    sort
}

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

prev=$(keyboards)
log "started; keyboards: $(echo "$prev" | grep -c .)"

while sleep "$INTERVAL"; do
  cur=$(keyboards)
  new=$(comm -13 <(echo "$prev" | cut -d' ' -f1) <(echo "$cur" | cut -d' ' -f1))
  if [[ -n "$new" ]]; then
    for id in $new; do
      log "new keyboard: $(echo "$cur" | grep "^$id " | awk '{ $1 = ""; sub(/^ +/, ""); print }' | tr -s ' ')"
    done
    log "restarting kanata"
    launchctl kickstart -k "$KANATA_JOB"
  fi
  prev=$cur
done
