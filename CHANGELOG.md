# Changelog — kiro-hyprland-dms

All notable changes to this config package are documented here.
Format: one entry per date (`YYYY.MM.DD`), newest first.

## 2026.10.05

### What Changed
- DMS's startup output is now saved to `$XDG_RUNTIME_DIR/dms-start.log`. On a QEMU live-ISO login the bar was
  missing: `dms run` started from `hyprland.start` left no process and no trace, while the same command run
  later in the session started DMS normally. The log should show why it exits at startup.
- **Fixed the missing bar at first login** (found with that log). `dms run` sometimes exited at once with
  `FATAL extract embedded UI: chtimes .../danklinux-shell/.extract-*/...: no such file or directory`. The
  first-run wallpaper script started at the same moment and called `dms ipc` every 0.5s, and `dms ipc` unpacks
  the embedded UI itself when it isn't there yet. Two unpacks into `$XDG_RUNTIME_DIR/danklinux-shell/` at
  once made `dms run` fail. The script now waits until DMS is up before its first `dms ipc` call. Without DMS
  there was also no wallpaper and the terminal's transparency showed only black, so both are fixed with it.
  It hit the live ISO on any boot and an installed system only on its first login.
- Keybindings now follow the active keyboard layout: `resolve_binds_by_sym = true` in the `input` block. With `us,be`
  (or `be,us`), Hyprland used to read every bind as if the first layout were active, so after Alt+Shift you typed
  AZERTY but Super+letter binds stayed on their QWERTY key positions. Now Super+A is the A printed on the key in
  whichever layout is active. Workspace binds use `code:` keys (physical positions) and are unchanged. Tested on a
  QEMU install of kiro-hyprland-dms.

### Technical Details
- The autostart `sh -c` first writes a timestamp and `WAYLAND_DISPLAY` to the log, then `exec dms run >>"$log" 2>&1`.
  The VirtualBox `LIBGL_ALWAYS_SOFTWARE` switch is unchanged.
- `firstrun-wallpaper.sh` polls `pgrep -u "$(id -u)" -x qs` every 0.5s, up to 60s, before its loop. `qs` only
  starts after `dms run` has finished unpacking, so the first `dms ipc` call finds the UI already in place.
  If `qs` never appears, the script exits without writing the stamp, so it tries again at the next login.
- Proven on the live ISO: with the unpacked UI folder moved aside, one `dms ipc call wallpaper get` created its
  own `.extract-*` folder.

### Files Modified
- `etc/skel/.config/kiro-hyprland-dms/hyprland.lua`
- `etc/skel/.config/kiro-hyprland-dms/scripts/firstrun-wallpaper.sh`
- `etc/skel/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua`

## 2026.10.04

### What Changed
- Added the user-friendly line to the `keybindings.txt` header: it lists the default bindings, and users can edit
  it to match their own. This brings it in line with `kiro-hyprland` and `kiro-niri-dms` (2026.09.27), where a
  user had expected the file to update itself after changing a binding.
- Keybinding sweep after the DMS reference ISO was trimmed: Super+Shift+X now opens `archlinux-logout` (same as
  Super+X) instead of `kiro-powermenu`, which needed rofi and is no longer on the ISO. Super+E and Super+F2 open
  Sublime Text (`subl`) instead of VS Code. Ctrl+Alt+H (`hyprland-tweak-tool`, dropped from the ISO) is removed.
  App keys for apps the ISO doesn't ship (Brave, Chromium, Vivaldi, OBS, GIMP, Inkscape...) stay on purpose.
- btop is now transparent like the terminals. Ctrl+Alt+End and Ctrl+Shift+Escape start it as
  `alacritty --class btop`, and the opacity rule only matched the class `Alacritty`, so btop stayed fully solid.
  btop now has its own, more transparent rule: 0.80 focused / 0.75 unfocused (terminals stay at 0.90 / 0.85).
  Values picked by eye on a QEMU install with a bright wallpaper.
- The Kiro wallpaper now really shows on first login. `firstrun-wallpaper.sh` stamped itself done as soon as
  `dms ipc call wallpaper set` succeeded, but DMS's backend answers before its UI finishes the first launch,
  which then starts with an empty wallpaper, so users saw DMS's default background. The script now keeps setting
  the wallpaper until `dms ipc call wallpaper get` returns `bg/kiro.jpg` on 10 checks in a row (~5s stable), for
  up to ~90s, and only then writes the stamp. Tested on a QEMU install with DMS's first-launch marker removed:
  session start 18:22:33, Kiro wallpaper at 18:22:37, stamp at 18:22:42.
- DMS now shows its bar in VirtualBox. There, VirtualBox's GPU paths broke DMS's GPU rendering: on VBoxSVGA the
  bar was missing after login, and on VMSVGA + 3D Hyprland dropped the shell over invalid dmabuf modifiers. The
  autostart now runs DMS with `LIBGL_ALWAYS_SOFTWARE=1` (Mesa llvmpipe, OpenGL on the CPU) when
  `systemd-detect-virt` reports `oracle`; real hardware and QEMU keep GPU rendering. A first version used
  `QT_QUICK_BACKEND=software`, but Qt's software renderer left parts of the bar (launcher, workspaces) blank
  until hovered. Tested on a VirtualBox install (VBoxSVGA): complete bar after login without hovering, Kiro
  wallpaper set, and still set after skipping DMS's welcome window. Tested on QEMU: DMS starts normally.

### Technical Details
- The new line is a `#` comment, which both kiro-keybindings parsers skip. Bindings are unchanged. All 111
  `bind()` calls in `hyprland.lua` were checked against the file, and every one is documented.

### Files Modified
- `etc/skel/.config/kiro-hyprland-dms/keybindings.txt`
- `etc/skel/.config/kiro-hyprland-dms/hyprland.lua`
- `etc/skel/.config/kiro-hyprland-dms/scripts/firstrun-wallpaper.sh`

## 2026.10.03

### What Changed
- Docs now name `dms-shell` as the DMS dependency instead of `dms-shell-hyprland`. Arch `extra` folded the split package back
  into `dms-shell` (1.6.2-2) and no longer ships it; the PKGBUILD in `KIROTUX-PKG-BUILD/kiro-hyprland-dms` was fixed to match.

### Technical Details
- `extra/dms-shell` lists `dms-shell-hyprland` in `replaces=` but not in `provides=`, so pacman swaps it out on upgrade and any
  `depends` on the old name becomes unsatisfiable.

### Files Modified
- `README.md`
- `CLAUDE.md`

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

### Also today: moved to the shared helper
- The private `scripts/screenshot.sh` above is **deleted** again in the same day, in favour of a
  shared `/usr/bin/kiro-screenshot` now shipped by `kiro-wayland-dotfiles` — already a dependency of
  this package. A sweep found the identical clipboard-only bind in eleven more Wayland editions, so
  the logic belongs in one place rather than being fixed twelve times. The DMS `screenshot`
  `begin`/`end` handshake documented above lives on inside the shared helper, guarded by
  `command -v dms` so it is a no-op on the editions that don't run DMS.
- Both binds now call `kiro-screenshot region` / `kiro-screenshot screen`. Behaviour is unchanged.
- **Build `kiro-wayland-dotfiles` before this package**: it provides the binary these binds call.

### Files Modified
- `etc/skel/.config/kiro-hyprland-dms/hyprland.lua`
- `etc/skel/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua`
- `etc/skel/.config/kiro-hyprland-dms/scripts/screenshot.sh` (added, then removed for the shared helper)
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
