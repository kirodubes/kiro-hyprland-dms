#!/bin/sh
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
#####################################################################
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
# Purpose:
#   At login, give a user without an Alacritty config a small one that
#   imports DMS's palette (~/.config/alacritty/dank-theme.toml), so the
#   terminals follow the wallpaper's colours.
# Why:
#   DMS's matugen rewrites dank-theme.toml on every wallpaper change, but
#   Alacritty only reads it when its config imports it, and this edition
#   starts without one. Alacritty watches imported files, so open
#   terminals recolour live. An existing alacritty.toml (yours or
#   kiro-dot-files') is never edited.
#####################################################################

config="$HOME/.config/alacritty/alacritty.toml"

[ -e "$config" ] && exit 0
mkdir -p "${config%/*}"
cat > "$config" <<'EOF'
# Created at login by kiro-hyprland-dms: the terminal takes the wallpaper's colours from DMS,
# which rewrites dank-theme.toml on every wallpaper change. Add your own settings below.
[general]
import = ["~/.config/alacritty/dank-theme.toml"]
EOF
