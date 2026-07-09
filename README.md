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
- `etc/skel/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua` — a complete
  working two-screen example (10+10 workspaces); see "Dual-monitor setup".
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

## Dual-monitor setup

**Out of the box this edition is single-monitor**: it accepts every connected
output at its preferred mode (`hl.monitor({ output = "", mode = "preferred",
position = "auto", scale = 1 })`) and gives you workspaces `1..10` on `SUPER + 1..0`.

It can also drive a **two-screen workstation** with 10 workspaces pinned to each
screen (chadwm-style 10 + 10: `SUPER` drives the left screen, `SUPER + ALT` the
right). Because monitors are identified by **hardware-specific names**, that layout
ships **disabled** — you enable it by editing your own config. Everything lives in
[`hyprland.lua`](etc/skel/.config/kiro-hyprland-dms/hyprland.lua); nothing else
needs to change.

> **Shortcut:** a complete, working two-screen config ships as
> [`hyprland-hq-dualscreen.lua`](etc/skel/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua).
> To use it, copy it over the default and edit only the monitor names/positions:
> ```bash
> cp ~/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua \
>    ~/.config/kiro-hyprland-dms/hyprland.lua
> ```
> The steps below build the same thing up piece by piece if you prefer.

### 1. Find your monitor names

Log in, open a terminal, and run:

```bash
hyprctl monitors
```

Each screen prints a `description:` line, e.g.
`description: BNQ BenQ GW2780 ABC1234`. You reference a monitor in the config as
`"desc:<that description>"`. (You can also use the short connector name like
`"DP-1"` / `"HDMI-A-1"`, but `desc:` survives replugging into a different port.)

### 2. Declare your two monitors

In `hyprland.lua`, find the **"Monitors & scaling"** section. The single-monitor
default is active:

```lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
```

Below it is a commented **"Dual monitor (OPTIONAL)"** block. **Comment out the
single-monitor line above**, then uncomment and edit the block, filling in your
own descriptions and pixel positions:

```lua
local mon_left  = "desc:BNQ BenQ GW2780 ABC1234"   -- your LEFT screen
local mon_right = "desc:BNQ BenQ GW2780 XYZ5678"   -- your RIGHT screen
hl.monitor({ output = mon_left,  mode = "1920x1080@60.0", position = "0x0",    scale = 1.0 })
hl.monitor({ output = mon_right, mode = "1920x1080@60.0", position = "1920x0", scale = 1.0 })
-- Left screen owns workspaces 1..10, right screen owns 11..20; `default` = startup ws.
for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i),      monitor = mon_left,  default = (i == 1) })
  hl.workspace_rule({ workspace = tostring(i + 10), monitor = mon_right, default = (i == 1) })
end
```

- **`position`** is the top-left pixel of each screen on the combined desktop.
  For two side-by-side 1080p screens, the left is `0x0` and the right starts
  where the left ends: `1920x0`. Adjust the second number if your screens have
  different widths or you want a gap/offset.
- **`mode`** is `WIDTHxHEIGHT@REFRESH`. Use a mode `hyprctl monitors` lists as
  available for that output, or keep `"preferred"` to let Hyprland pick.
- **`scale`** stays `1.0` for 1080p/1440p; see the HiDPI note further down in the
  file for 4K/retina.

### 3. Enable the two-screen keybinds (10 + 10)

By default `SUPER + 1..0` selects workspaces `1..10`. To drive the **right**
screen with `SUPER + ALT + 1..0` (workspaces `11..20`), find the **"Workspaces
1..10"** keybind loop near the bottom of `hyprland.lua` and replace it with:

```lua
for i = 1, 10 do
  local key   = "code:" .. tostring(i + 9)   -- code:10 = "1" … code:19 = "0"
  local left  = tostring(i)                  -- 1..10  → left monitor
  local right = tostring(i + 10)             -- 11..20 → right monitor

  bind(mod .. " + " .. key,               "Workspace " .. left,          hl.dsp.focus({ workspace = left }))
  bind(mod .. " + CTRL + " .. key,        "Move to workspace " .. left,  hl.dsp.window.move({ workspace = left }))
  bind(mod .. " + SHIFT + " .. key,       "Send to workspace " .. left,  hl.dsp.window.move({ workspace = left, follow = false }))

  bind(mod .. " + ALT + " .. key,         "Workspace " .. right,         hl.dsp.focus({ workspace = right }))
  bind(mod .. " + ALT + CTRL + " .. key,  "Move to workspace " .. right, hl.dsp.window.move({ workspace = right }))
  bind(mod .. " + ALT + SHIFT + " .. key, "Send to workspace " .. right, hl.dsp.window.move({ workspace = right, follow = false }))
end
```

`CTRL` moves the focused window (and follows it); `SHIFT` sends it without
following; `ALT` selects the right screen.

### 4. (Optional) Pin specific apps to a screen

To always open an app on a given workspace/screen, add a window rule in the
**"Window rules"** section (there is a commented example there). For instance, to
park Firefox on workspace 10 (left screen) and Vivaldi on 20 (right screen):

```lua
hl.window_rule({ match = { class = "^(firefox)$" },          workspace = "10 silent" })
hl.window_rule({ match = { class = "^([Vv]ivaldi-stable)$" }, workspace = "20 silent" })
```

`silent` means the window opens there without stealing focus. Find an app's class
with `hyprctl clients` (look at the `class:` field).

### 5. Apply

Save the file and reload Hyprland with **`SUPER + SHIFT + R`** (or log out and
back in). If a screen stays black or misplaced, re-check its `desc:` string and
`position` against `hyprctl monitors`.
