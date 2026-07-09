# kiro-hyprland-dms — Claude project instructions

## Overview
Config package for the **Kiro Hyprland + DankMaterialShell edition** — the
Material-3 member of the KIROTUX Wayland line on the Hyprland compositor, sibling
to [kiro-hyprland](../kiro-hyprland/CLAUDE.md) (classic waybar/mako/rofi stack)
and [kiro-hyprland-noctalia](../kiro-hyprland-noctalia/CLAUDE.md) (noctalia-shell).
Same Hyprland compositor, DMS as the shell. It is the Hyprland twin of
[kiro-niri-dms](../kiro-niri-dms/CLAUDE.md). Public, open-core, shipped via
`nemesis_repo`.

## Edition spec (the WM-variable matrix)
- **Compositor:** Hyprland 0.55+ (wlroots-based; native XWayland).
- **Config language:** Lua (`hl.*` API). Single `etc/skel/.config/kiro-hyprland-dms/hyprland.lua`
  (Hyprland pointed at it by the `kiro-hyprland-dms-session` wrapper via `--config`).
- **Desktop shell:** **DankMaterialShell (DMS)** — a Quickshell + Material 3 shell
  (`dms-shell-hyprland` from Arch `extra`, which pulls `dms-shell` for the `dms`
  CLI). Provides bar, launcher (spotlight), lock, notifications, wallpaper, control
  center, session menu, polkit agent. Started with `dms run`; driven over
  `dms ipc call <target> <function>` (docs: danklinux.com/docs/dankmaterialshell).
- **Autostart:** on `hyprland.start` — `dbus-update-activation-environment`,
  `systemctl --user import-environment`, `xdg-user-dirs-update`, the GTK→gsettings
  import helper, `dms run`, the guarded first-run wallpaper script, and the
  archiso-gated Calamares line. NO waybar / mako / swaybg / hypridle / nm-applet /
  polkit-gnome — DMS owns all of that.
- **Theming:** DMS owns runtime accent colours (runs matugen internally) for its
  bar + GTK apps. Hyprland's focus border is a **static** Kiro colour (Material
  default `#d0bcff`), NOT matugen-driven — see gotcha below. Base GTK look + cursor
  shipped via `/etc/dconf/`, owned by `kiro-wayland-dotfiles` (dconf consumer).
- **Dependency note:** `dms-shell-hyprland` (+ `dms-shell`, `quickshell`, `dgop`,
  `accountsservice`) all come from Arch `extra` — nothing repackaged by Kiro.
  `matugen`, `cava`, `kimageformats` added for DMS. `power-profiles-daemon` is an
  optdepend (DMS `powerprofile` IPC). No `xwayland-satellite` (Hyprland has native
  XWayland, unlike the niri sibling).

## Keybindings
- Hyprland-native window/master/workspace/group management **kept** from
  `kiro-hyprland`; Kiro's app scheme layered on (CTRL+ALT launchers + SUPER+F1..F12
  + `kiro-keybindings` on SUPER+CTRL+S).
- Shell binds route to DMS: launcher `spotlight toggle`, control center
  `control-center toggle`, settings `settings toggle`, lock `lock lock`, wallpaper
  `dankdash wallpaper`, clipboard `clipboard toggle`, notifications
  `notifications toggle`; media/volume/brightness via `audio`/`mpris`/`brightness`
  targets, all with `{ locked = true }` so they work on the lock screen. These IPC
  target names are kept identical to `kiro-niri-dms` (same DMS daemon) so the two
  DMS editions behave the same.
- `keybindings.txt` mirrors `hyprland.lua` — keep them in lockstep; a
  duplicate-chord scan must pass. (`kiro-keybindings` still needs a Hyprland-DMS
  entry only if detection ever diverges from plain Hyprland.)
- Mod = Super. `us,be` layout (matches the rest of the Kiro line).

## Patterns / gotchas
- **DMS's own `dms setup` fully manages `~/.config/hypr/`** (writes `hyprland.lua`
  + `dms/*.lua` matugen fragments and expects `require("dms.*")`). This edition
  deliberately does NOT use that path or those requires — it ships its own config
  folder with a **static** Kiro border. The trade: the border is fixed instead of
  wallpaper-derived. DMS still themes its bar + GTK apps fine.
- **Wallpaper on Hyprland needs no backdrop rule.** DMS paints the wallpaper on a
  Quickshell background layer-shell surface (namespace `quickshell`); Hyprland
  renders background layers behind windows natively, so it "just works". This
  differs from the niri sibling, which needs `place-within-backdrop true` (a
  niri-only feature). Do NOT copy that rule here; do NOT add swaybg.
  `hl.layer_rule({ namespace = "^(quickshell)$", no_anim = true })` (DMS's own
  blessed Hyprland rule) is kept so the shell doesn't flicker on reload.
- `hl.exec_cmd` execs argv directly (no shell) — the archiso-gated installer line
  is wrapped in `sh -c '…'` so the `[ ]` test + `&&` are interpreted.
- No DMS `settings.json` is seeded (runtime-generated; a partial seed risks its
  schema). Wallpaper is branded once via `scripts/firstrun-wallpaper.sh` (guarded,
  polls for `dms ipc` readiness) — same pattern as `kiro-niri-dms`.

## Quickshell / noctalia incompatibility (hard conflict)
- DMS 1.5.0 needs the **modern upstream `quickshell`** (extra, 0.3.0+). The **noctalia editions**
  (`kiro-hyprland-noctalia`, `kiro-niri-noctalia`, `kiro-hyprland-noctura`) pull `noctalia-shell` →
  **`noctalia-qs`**, noctalia's own pinned Quickshell fork that `Provides`+`Conflicts` `quickshell`
  and is too old for DMS (its `FileBrowserModal.qml` references a `parentWindow` property absent in
  `noctalia-qs 0.0.12` → Quickshell exits 255 → the DMS shell/bar/wallpaper **silently never
  render**, though the DMS go backend still answers IPC — a false "working" signal).
- So the recipe lists **`quickshell` explicitly** in `depends` and **`conflicts=('noctalia-qs')`**,
  making pacman refuse the incompatible mix at install time instead of shipping a black shell.
  Consequence: **kiro-hyprland-dms cannot coexist with the noctalia editions** on one system (it
  still coexists fine with the classic `kiro-hyprland`). Diagnosed on picard 2026-07-09; fix scoped
  to this edition only for now (`kiro-niri-dms` has the same latent issue, left untouched). See
  memory `dms-vs-noctalia-quickshell-conflict`.

## Sibling editions
- **`kiro-hyprland`** (waybar/mako/rofi) and **`kiro-hyprland-noctalia`**
  (noctalia-shell) — same compositor, different shells. All ship **their own**
  config folder (`~/.config/kiro-hyprland-dms/` vs `kiro-hyprland/` vs
  `kiro-hyprland-noctalia/`), session `.desktop` and wrapper — **no shared files,
  no conflicts** — so all coexist and are picked per-login.
- Each edition ships its own hide-upstream helper + hook (own filenames, so no
  conflict). The remove `.install` un-hide of upstream "Hyprland" is guarded to
  only fire when no sibling Kiro Hyprland edition remains.

## Build / delivery
- Source-of-truth for the config; delivered as the `kiro-hyprland-dms` package via
  `../KIROTUX-PKG-BUILD/kiro-hyprland-dms/build.sh` (public recipe →
  `~/EDU/nemesis_repo/`). After editing here: rebuild the package (recipe
  `build.sh` or `flow-kiro-hyprland-dms`), then the ISO to test a fresh install.
- **Not boot-tested at authoring time** — Wayland-GPU editions black-screen in
  VirtualBox (no render node); verify on QEMU virtio-gpu or real metal before an
  ISO release (see the niri-dms lesson).
- See [../CLAUDE.md](../CLAUDE.md) for the full KIROTUX delivery architecture.
