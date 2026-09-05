# Changelog — kiro-hyprland-dms

All notable changes to this config package are documented here.
Format: one entry per date (`YYYY.MM.DD`), newest first.

## 2026.09.05

### What Changed
- **Print now actually produces a screenshot you can find.** The Print / super+Print
  binds were never broken in the mechanical sense — the key arrived, the bind fired,
  slurp's overlay came up and grim ran — but the command was
  `grim -g "$(slurp)" - | wl-copy`, so the image went to the clipboard and nowhere
  else: no file, no notification, no visible result. Coming from chadwm, where Print
  writes a PNG into `~/Pictures` via scrot, that reads as a dead key. Both binds now
  call a new `scripts/screenshot.sh`, which saves a timestamped PNG in
  `~/Pictures/Screenshots`, still copies it to the clipboard, and raises a
  notification with a thumbnail and the path.

### Technical Details
- New `etc/skel/.config/kiro-hyprland-dms/scripts/screenshot.sh` — takes `region`
  (default, drag a rectangle with slurp) or `screen` (whole output). Writes
  `${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots/<YYYY-MM-DD_HH-MM-SS>.png`, pipes
  it to `wl-copy`, then `notify-send -i "$shot"` so the toast carries a thumbnail.
- The grab is wrapped in DMS's `dms ipc call screenshot begin` / `end` handshake.
  That IPC pair is **not** a screenshot tool — the DMS source (`IpcHandler`,
  `target: "screenshot"`) only flips `PopoutManager.screenshotActive`, which pulls
  DMS's popouts off screen for the duration so a half-faded panel doesn't land in the
  shot. Only DMS's `niri` IPC target exposes real screenshot actions, which is why
  `kiro-niri-dms` can bind them directly and this edition cannot.
- The handshake is closed **before** `notify-send`, not in the trap alone: while
  `screenshotActive` is set, the suppressed popout layer swallows the very toast the
  fix exists to show. The `trap ... EXIT` remains as an idempotent safety net so a
  cancelled selection can't leave DMS with its popouts stuck hidden.
- `slurp` exits non-zero when the selection is cancelled (Esc / right-click), so
  `geometry=$(slurp) || exit 0` treats cancel as success — under `set -euo pipefail`
  it would otherwise abort as an error and write a stray zero-byte PNG.
- Note for future debugging: `hl.dsp.exec_cmd` (the keybind dispatcher) **does** run
  through a shell — pipes and `$( )` in binds are fine. Only `hl.exec_cmd` / `on_start`
  (autostart) execs argv directly and needs `sh -c`. The two are easy to conflate, and
  conflating them sends you looking for a quoting bug in the binds that isn't there.
- Verified on picard against the live session: config reloads clean, both binds
  register, `screen` mode writes a valid 1920x1080 PNG plus clipboard plus toast, and
  the cancel path exits cleanly leaving no file and DMS mode back OFF.

### Files Modified
- `etc/skel/.config/kiro-hyprland-dms/scripts/screenshot.sh` (new)
- `etc/skel/.config/kiro-hyprland-dms/hyprland.lua`
- `etc/skel/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua`
- `etc/skel/.config/kiro-hyprland-dms/keybindings.txt`

## 2026.07.09

### What Changed
- **Fix broken variety tray icon on the DMS bar.** Forced `QT_QPA_PLATFORMTHEME=gtk3`
  in `hyprland.lua` so DMS's Qt6 Quickshell bar resolves SNI tray icons through the
  gsettings icon theme (Surfn). Previously the global `/etc/environment`
  `QT_QPA_PLATFORMTHEME=qt5ct` (a Qt5 plugin Qt6 can't load, no `qt6ct` installed)
  left Quickshell on the `hicolor` fallback, so app-specific tray names like
  `variety-indicator` — which live only in Surfn's `panel/` context — went blank and
  fell back to the default icon. DMS already exported `QT_QPA_PLATFORMTHEME_QT6=gtk3`,
  but Qt6 does not honour the versioned variable, so it was a no-op; the plain env now
  overrides the global for this session. Diagnosed on picard (verified with a PySide6
  probe: `qt5ct`→themeName `hicolor`, icon missing; `gtk3`→`Surfn`, icon resolves).

### What Changed (initial package)
- Initial config package: the **Hyprland + DankMaterialShell (DMS)** edition of
  the Kiro Wayland line. Sibling to `kiro-hyprland` (classic waybar stack) and
  `kiro-hyprland-noctalia` (noctalia-shell), on the same Hyprland compositor with
  DMS as the shell.

### Technical Details
- `etc/skel/.config/kiro-hyprland-dms/hyprland.lua` — Hyprland 0.55+ Lua config
  based on the classic `kiro-hyprland` edition, with the whole classic shell
  layer removed (no waybar / mako / swaybg / rofi / hypridle / hyprlock /
  nm-applet / polkit-gnome). The desktop is DMS: `dms run` starts it, shell
  functions route to `dms ipc call` (spotlight / control-center / settings /
  lock / clipboard / notifications / audio / mpris / brightness).
- Own config folder + session: `kiro-hyprland-dms-session` starts
  `uwsm start -- Hyprland --config ~/.config/kiro-hyprland-dms/hyprland.lua`;
  ships as "Kiro Hyprland Dms". A hide-upstream helper + pacman hook stamp
  `NoDisplay=true` on upstream `hyprland.desktop` / `hyprland-uwsm.desktop`.
- Wallpaper is drawn by DMS on its Quickshell background layer (namespace
  `quickshell`), which Hyprland renders behind windows natively — no swaybg and
  no niri-style backdrop rule. `hl.layer_rule` disables animations on that layer.
  First login branding via `scripts/firstrun-wallpaper.sh` (guarded, polls
  `dms ipc call wallpaper set`).
- Static Kiro focus border (Material default accent); DMS themes its own bar +
  GTK apps from the wallpaper via matugen at runtime — this edition does NOT use
  DMS's `dms setup` (`~/.config/hypr/` + `require("dms.*")`) path.

### Files Modified
- `etc/skel/.config/kiro-hyprland-dms/` (hyprland.lua, keybindings.txt, bg/kiro.jpg,
  scripts/import-gsettings.sh, scripts/firstrun-wallpaper.sh)
- `usr/bin/kiro-hyprland-dms-session`, `usr/bin/kiro-hyprland-dms-hide-upstream-session`
- `usr/share/wayland-sessions/kiro-hyprland-dms.desktop`
- `usr/share/libalpm/hooks/kiro-hyprland-dms-hide-upstream-session.hook`
- `README.md`, `CLAUDE.md`, `up.sh`, `setup.sh`, `.gitignore`, `kiro.jpg`
