# Changelog — kiro-hyprland-dms

All notable changes to this config package are documented here.
Format: one entry per date (`YYYY.MM.DD`), newest first.

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
