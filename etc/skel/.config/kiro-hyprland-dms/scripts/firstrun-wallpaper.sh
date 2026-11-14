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
#   Kiro-branded out of the box, and switch DMS to its wallpaper (dynamic)
#   theme so its matugen palette follows every wallpaper. Each step has
#   its own stamp file, so each runs exactly once.
# Why:
#   This edition ships no DMS settings.json (DMS generates its own at
#   runtime, and a hand-seeded partial file risks breaking its schema), so
#   both are set over IPC instead. `dms ipc call` only works once the
#   shell is up, so poll for it rather than racing a fixed sleep. Once
#   stamped a step is a no-op, so it never fights a wallpaper or theme the
#   user later picks in DMS. The theme step came later (2026.10.23) with
#   its own stamp, so existing installs get it once at their next login.
#####################################################################

dir="$HOME/.config/kiro-hyprland-dms"
stamp="$dir/.firstrun-wallpaper-done"
# v2 (2026.11.14): the first version lost the switch (see dynamic_theme), so installs stamped by it get one retry
theme_stamp="$dir/.firstrun-dynamic-theme-v2-done"
theme_tries="$dir/.firstrun-dynamic-theme-tries"
wallpaper="$dir/bg/kiro.jpg"

[ -e "$stamp" ] && [ -e "$theme_stamp" ] && exit 0

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
set_wallpaper() {
    [ -e "$stamp" ] && return 0
    [ -f "$wallpaper" ] || return 0
    i=0
    stable=0
    while [ "$i" -lt 180 ]; do
        if [ "$(dms ipc call wallpaper get 2>/dev/null)" = "$wallpaper" ]; then
            stable=$((stable + 1))
            if [ "$stable" -ge 10 ]; then
                : > "$stamp"
                return 0
            fi
        else
            stable=0
            dms ipc call wallpaper set "$wallpaper" >/dev/null 2>&1
        fi
        i=$((i + 1))
        sleep 0.5
    done
}

# DMS starts on its fixed purple theme, so the bar, apps and Alacritty would not follow the wallpaper.
# Only that untouched default is switched to the wallpaper (dynamic) theme: a theme the user picked stays.
# DMS applies a theme set over IPC only after a restart. Not confirmed: no stamp, try again at the next login (3 max).
dynamic_theme() {
    [ -e "$theme_stamp" ] && return 0
    tries="$(cat "$theme_tries" 2>/dev/null || echo 0)"
    [ "$tries" -ge 3 ] && return 0
    theme="$(theme_name)"
    [ -n "$theme" ] || return 0
    if [ "$theme" = '"purple"' ]; then
        echo $((tries + 1)) > "$theme_tries"
        dms ipc call settings set currentThemeName dynamic >/dev/null 2>&1 || return 0
        # DMS saves a setting a moment after `set`: a restart right away loses it, which is why the first version
        # of this step never worked (proven on picard, 2026-11-14). Wait, restart, and only stamp a confirmed switch.
        sleep 2
        dms restart >/dev/null 2>&1
        sleep 3
        [ "$(theme_name)" = '"dynamic"' ] || return 0
    fi
    : > "$theme_stamp"
    rm -f "$theme_tries"
}

# DMS's theme name as JSON ("purple"), or empty when DMS doesn't answer within ~30s. Right after a start it first
# answers "No running instances" and then "Target not found"; only a quoted value is real.
theme_name() {
    i=0
    while [ "$i" -lt 60 ]; do
        theme="$(dms ipc call settings get currentThemeName 2>/dev/null)"
        case "$theme" in \"*) echo "$theme"; return 0 ;; esac
        i=$((i + 1))
        sleep 0.5
    done
}

set_wallpaper
dynamic_theme
exit 0
