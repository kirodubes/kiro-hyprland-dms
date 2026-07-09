# kiro-hyprland-dms

The **Hyprland + DankMaterialShell edition** of Kiro — the Material-3 member of
the Kiro Wayland line on the Hyprland compositor (sibling to
[kiro-hyprland](https://github.com/kirodubes/kiro-hyprland) and
[kiro-hyprland-noctalia](https://github.com/kirodubes/kiro-hyprland-noctalia)).

## What it is

A configuration package: the source-of-truth config tree for Kiro's Hyprland
"DMS" edition. Hyprland is the Wayland compositor; the desktop shell (bar,
launcher, lock screen, notifications, wallpaper, control center, session menu,
polkit agent) is provided by **DankMaterialShell (DMS)** — a Quickshell +
Material 3 shell — started with `dms run` and driven over
`dms ipc call <target> <function>`. Hyprland is the compositor; DMS is
everything else.

This is the sibling of `kiro-hyprland` (same compositor, classic
waybar + mako + rofi stack) and `kiro-hyprland-noctalia` (noctalia-shell). All
Hyprland editions coexist on one system, each in its own config folder, picked
per-login.

## What it ships

- `etc/skel/.config/kiro-hyprland-dms/` — the Hyprland Lua config
  (`hyprland.lua`), a `keybindings.txt` cheat sheet, a GTK→gsettings import
  helper, the Kiro wallpaper (`bg/kiro.jpg`) and a first-run script that points
  DMS's wallpaper at it.
- `usr/bin/kiro-hyprland-dms-session` + `usr/share/wayland-sessions/kiro-hyprland-dms.desktop`
  — the "Kiro Hyprland Dms" login entry, which starts Hyprland under uwsm pointed
  at this edition's own config folder.
- A pacman hook that keeps upstream's plain "Hyprland" sessions hidden.

## How to install

```sh
sudo pacman -S kiro-hyprland-dms
```

`kiro-hyprland-dms` depends on `hyprland` + `dms-shell-hyprland` (both in Arch
`extra`) plus the usual Wayland helpers. On a fresh login Hyprland starts DMS
(`dms run`), which paints the bar and wallpaper and derives its Material palette
from it. Press **Super + Ctrl + S** for the searchable keybindings cheat sheet.

A pristine copy of the config is kept at `/usr/share/kiro/kiro-hyprland-dms/` so
it can be restored.
