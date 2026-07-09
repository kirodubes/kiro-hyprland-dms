#!/bin/sh
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
#####################################################################
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
# Purpose:
#   On the FIRST login of the Kiro Hyprland (DankMaterialShell) edition, set
#   DMS's wallpaper to the shipped Kiro wallpaper so the desktop is
#   Kiro-branded out of the box (DMS then derives its matugen palette from
#   it). Guards on a stamp file so it runs exactly once.
# Why:
#   This edition ships no DMS settings.json (DMS generates its own at
#   runtime, and a hand-seeded partial file risks breaking its schema), so
#   the wallpaper is set over IPC instead. `dms ipc call` only works once
#   the shell is up, so poll for it rather than racing a fixed sleep. Once
#   stamped this is a no-op, so it never fights a wallpaper the user later
#   picks in DMS.
#####################################################################

stamp="$HOME/.config/kiro-hyprland-dms/.firstrun-wallpaper-done"
wallpaper="$HOME/.config/kiro-hyprland-dms/bg/kiro.jpg"

[ -e "$stamp" ] && exit 0
[ -f "$wallpaper" ] || exit 0

# Poll for DMS IPC to come up (up to ~30s), then set the wallpaper.
i=0
while [ "$i" -lt 60 ]; do
    if dms ipc call wallpaper set "$wallpaper" >/dev/null 2>&1; then
        : > "$stamp"
        exit 0
    fi
    i=$((i + 1))
    sleep 0.5
done

exit 0
