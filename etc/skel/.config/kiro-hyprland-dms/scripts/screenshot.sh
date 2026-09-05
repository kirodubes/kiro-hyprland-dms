#!/usr/bin/env bash
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
#####################################################################
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
# Purpose:
#   Take a screenshot on the Kiro Hyprland (DankMaterialShell) edition and
#   actually leave something behind: a timestamped PNG in
#   ~/Pictures/Screenshots, the image on the clipboard, and a notification
#   showing where it landed. "region" (default) lets you drag a rectangle,
#   "screen" grabs the whole output.
# Why:
#   The binds this replaces piped grim straight into wl-copy. That worked,
#   but wrote no file and gave no feedback, so Print looked like a dead key.
#   The grab is wrapped in DMS's `screenshot begin`/`end` handshake, which
#   sets PopoutManager.screenshotActive so DMS pulls its popouts off screen
#   for the duration -- otherwise a half-faded panel ends up in the shot.
#   The handshake is closed again *before* notify-send, because a suppressed
#   popout layer would swallow the very toast we want to see.
#####################################################################

set -euo pipefail

mode="${1:-region}"

shotdir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$shotdir"
shot="$shotdir/$(date +%Y-%m-%d_%H-%M-%S).png"

dms_screenshot_mode() {
    dms ipc call screenshot "$1" >/dev/null 2>&1 || true
}

dms_screenshot_mode begin
trap 'dms_screenshot_mode end' EXIT

case "$mode" in
    region)
        # slurp exits non-zero when the selection is cancelled (Esc / right-click)
        geometry=$(slurp) || exit 0
        grim -g "$geometry" "$shot"
        ;;
    screen)
        grim "$shot"
        ;;
    *)
        echo "usage: $(basename "$0") [region|screen]" >&2
        exit 1
        ;;
esac

dms_screenshot_mode end

wl-copy < "$shot"
notify-send -a Screenshot -i "$shot" "Screenshot saved" "$shot"
