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

# `dms ipc` unpacks the embedded UI itself when it isn't there yet; calling it while `dms run`
# is still unpacking at first login makes `dms run` exit (FATAL extract embedded UI). Wait for qs.
n=0
until pgrep -u "$(id -u)" -x qs >/dev/null; do
    n=$((n + 1)); [ "$n" -ge 120 ] && exit 0
    sleep 0.5
done

# DMS's backend answers IPC before the UI has finished its first launch, and that first
# launch starts with an empty wallpaper again. So a successful `set` is not enough: keep
# setting until `get` returns the Kiro wallpaper on 10 checks in a row (~5s stable), for up
# to ~90s. Only then write the stamp.
i=0
stable=0
while [ "$i" -lt 180 ]; do
    if [ "$(dms ipc call wallpaper get 2>/dev/null)" = "$wallpaper" ]; then
        stable=$((stable + 1))
        if [ "$stable" -ge 10 ]; then
            : > "$stamp"
            exit 0
        fi
    else
        stable=0
        dms ipc call wallpaper set "$wallpaper" >/dev/null 2>&1
    fi
    i=$((i + 1))
    sleep 0.5
done

exit 0
