-- ════════════════════════════════════════════════════════════════════════
-- Kiro Hyprland (DankMaterialShell) — HQ dual-monitor config  (hyprland-hq-dualscreen.lua)
-- ════════════════════════════════════════════════════════════════════════
-- A COMPLETE, WORKING two-screen setup (10 workspaces pinned per screen,
-- SUPER = left / SUPER+ALT = right) kept as a real-world reference alongside the
-- single-monitor default. It targets a specific dual-BenQ workstation, so the
-- `desc:` monitor strings and positions below are hardware-specific — swap in
-- yours (`hyprctl monitors`). See the README "Dual-monitor setup" section.
-- To activate it, replace the default config:
--   cp ~/.config/kiro-hyprland-dms/hyprland-hq-dualscreen.lua \
--      ~/.config/kiro-hyprland-dms/hyprland.lua
-- then edit the monitor `desc:`/positions and reload (SUPER+SHIFT+R).
-- ────────────────────────────────────────────────────────────────────────
-- Target: Hyprland 0.55+ (Lua config format; hyprlang/.conf deprecated in 0.55).
-- Lives at: ~/.config/kiro-hyprland-dms/hyprland.lua
--   Hyprland is pointed here by the kiro-hyprland-dms-session wrapper via
--   `Hyprland --config`, so this edition never touches ~/.config/hypr/ and can
--   coexist with the sibling kiro-hyprland / kiro-hyprland-noctalia editions.
--
-- Desktop shell: DankMaterialShell (DMS) — a Quickshell + Material 3 shell that
-- provides the bar, launcher (spotlight), lock screen, notifications, wallpaper,
-- control center, session menu and polkit agent. Hyprland is only the compositor;
-- everything else is DMS, started with `dms run` and driven over
-- `dms ipc call <target> <function>`.
--
-- Modeled on Omarchy's Lua config (the modern mainline reference) but carrying
-- Kiro/ArcoLinux's SUPER-based keybind philosophy. Uses ONLY the native hl.* API.
--
-- API reference: https://wiki.hypr.land/Configuring/Start/
-- DMS IPC:       https://danklinux.com/docs/dankmaterialshell
-- ────────────────────────────────────────────────────────────────────────

local mod = "SUPER"

-- Kiro app defaults — adjust to the shipped Kiro toolset.
local term        = "alacritty"
local files       = "thunar"
local browser     = "firefox"
local editor      = "code"
local logout      = "archlinux-logout"   -- Kiro logout dialog (archlinux-logout-gtk4), as on the other editions
local powermenu   = "kiro-powermenu"
local keybindings = "kiro-keybindings"   -- searchable PySide6/QML cheatsheet (auto-detects Hyprland)

-- DMS shell entry points (dms ipc call <target> <function>).
local dms_launcher     = "dms ipc call spotlight toggle"
local dms_controlpanel = "dms ipc call control-center toggle"
local dms_settings     = "dms ipc call settings toggle"
local dms_lock         = "dms ipc call lock lock"
local dms_wallpaper    = "dms ipc call dankdash wallpaper"
local dms_clipboard    = "dms ipc call clipboard toggle"
local dms_notifs       = "dms ipc call notifications toggle"

-- ── Environment ──────────────────────────────────────────────────────────
-- Force Wayland across toolkits; advertise the session to portals/screenshare.
hl.env("XCURSOR_SIZE", "12")
hl.env("HYPRCURSOR_SIZE", "12")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Force the gtk3 Qt platform theme so DMS's Qt6 Quickshell bar resolves SNI tray
-- icons via the gsettings icon theme (Surfn). The global /etc/environment sets
-- QT_QPA_PLATFORMTHEME=qt5ct, which Qt6 can't load (no qt6ct) → it falls back to
-- hicolor and app-specific tray icons like variety-indicator go blank. DMS exports
-- QT_QPA_PLATFORMTHEME_QT6=gtk3, but Qt6 does not honour the versioned variable, so
-- the plain one must win here.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- VM compatibility (VirtualBox/VMware): hardware cursors + hardware rendering are broken in
-- VMs. Without these, enabling VM "3D acceleration" black-screens Hyprland. Harmless on real
-- hardware (ALLOW_SOFTWARE only permits a fallback; it still uses the GPU when present).
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- ── Monitors & scaling ─────────────────────────────────────────────────────
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/  (`hyprctl monitors` to list).
-- Default: every output, preferred mode, auto position, scale 1 (good for 1080p/1440p).
-- Single Monitor
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Dual monitor
hl.monitor({
    output = "desc:BNQ BenQ GW2780 K1M0156201Q",
    mode = "1920x1080@60.0",
    position = "2429x0",
    scale = 1.0
})
hl.monitor({
    output = "desc:BNQ BenQ GW2780 K1M0106301Q",
    mode = "1920x1080@60.0",
    position = "509x0",
    scale = 1.0
})

-- ── Workspaces pinned to monitors (chadwm-style 10 + 10) ───────────────────
-- Left screen owns workspaces 1..10, right screen owns 11..20. Because each
-- workspace is bound to a monitor, `focus`/`move` on a workspace number always
-- lands on that screen — so the number keys drive one screen and SUPER+ALT the
-- other (see the keybind loop below). `default` picks each screen's startup ws.
local mon_left  = "desc:BNQ BenQ GW2780 K1M0106301Q"   -- position 509x0  (left)
local mon_right = "desc:BNQ BenQ GW2780 K1M0156201Q"   -- position 2429x0 (right)
for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i),      monitor = mon_left,  default = (i == 1) })
  hl.workspace_rule({ workspace = tostring(i + 10), monitor = mon_right, default = (i == 1) })
end

hl.env("GDK_SCALE", "1")
-- HiDPI: bump both for crisp scaling, e.g.
--   retina 2x (13" 2.8K / 27" 5K):  scale = 2    + GDK_SCALE 2
--   27"/32" 4K (fractional):        scale = 1.6  + GDK_SCALE 1.75
-- Portrait/rotated secondary: add transform = 1 (90°) or 3 (270°) to the spec.

-- ── Look & feel ────────────────────────────────────────────────────────────
-- Static Kiro focus border. DMS themes its own bar + GTK apps from the wallpaper
-- at runtime (matugen); the Hyprland border stays fixed (Material default accent).
local active_border   = { colors = { "rgba(d0bcffaa)", "rgba(9a82dbaa)" }, angle = 45 }
local inactive_border = "rgba(414868aa)"

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 7,
    border_size = 2,
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
    layout = "master",            -- Kiro/ArcoLinux default; "dwindle" also available
    resize_on_border = true,
    extend_border_grab_area = 5,
    allow_tearing = false,
  },

  decoration = {
    rounding = 5,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
    -- Dim unfocused windows a little for focus contrast; dim more behind an open scratchpad
    -- so the popped-up window reads clearly on top.
    dim_inactive = true,
    dim_strength = 0.06,
    dim_special = 0.2,
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
    mfact = 0.5,
  },

  input = {
    kb_layout = "us,be",                            -- US + Belgian
    kb_options = "grp:alt_shift_toggle,compose:caps",  -- Alt+Shift switches layouts; Caps = Compose
    repeat_rate = 40,
    repeat_delay = 600,
    follow_mouse = 1,
    numlock_by_default = true,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      drag_lock = true,
      disable_while_typing = true,
    },
  },

  binds = {
    workspace_back_and_forth = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    disable_watchdog_warning = true, -- we launch Hyprland --config directly (no start-hyprland wrapper)
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    focus_on_activate = true,
    on_focus_under_fullscreen = 1,
  },

  cursor = {
    hide_on_key_press = true,
  },
})

-- ── Animations (bezier curves + per-leaf, 0.53+ style) ─────────────────────
hl.config({ animations = { enabled = true } })
hl.curve("kiroEase",      { type = "bezier", points = { { 0.05, 0.9 },  { 0.1, 1.05 } } })
hl.curve("kiroSnap",      { type = "bezier", points = { { 0.16, 1 },    { 0.3, 1 } } })
hl.curve("kiroOvershoot", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.animation({ leaf = "windows",          enabled = true, speed = 7,  bezier = "kiroEase" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 7,  bezier = "default",       style = "popin 80%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10, bezier = "kiroSnap" })
hl.animation({ leaf = "fade",             enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 6,  bezier = "kiroSnap",      style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5,  bezier = "kiroOvershoot",  style = "slidevert" })

-- ── Window rules (0.53+ unified hl.window_rule) ────────────────────────────
hl.window_rule({ match = { class = "^(Spotify)$" }, tile = true })
-- Firefox → always open on workspace 10 (silent = don't yank focus to it on launch).
hl.window_rule({ match = { class = "^(firefox)$" }, workspace = "10 silent" })
-- Vivaldi → workspace 20, Opera → workspace 19 (both silent).
hl.window_rule({ match = { class = "^([Vv]ivaldi-stable)$" }, workspace = "20 silent" })
hl.window_rule({ match = { class = "^([Oo]pera)$" },          workspace = "19 silent" })
-- Pin workspaces to screens (persistent = always exist there):
--   10 → LEFT screen  (BenQ at 509x0);  19 & 20 → RIGHT screen (BenQ at 2429x0).
hl.workspace_rule({ workspace = "10", monitor = "desc:BNQ BenQ GW2780 K1M0106301Q", persistent = true })
hl.workspace_rule({ workspace = "20", monitor = "desc:BNQ BenQ GW2780 K1M0156201Q", persistent = true })
hl.workspace_rule({ workspace = "19", monitor = "desc:BNQ BenQ GW2780 K1M0156201Q", persistent = true })
-- Smooth touchpad scrolling in terminals (from nemesis input config):
hl.window_rule({ match = { class = "(Alacritty|kitty)" }, scroll_touchpad = 1.5 })
-- Transparent terminal — compositor opacity (works in VBox/QEMU/bare-metal alike; Hyprland's
-- blur frosts it). active/inactive: 0.90/0.85.
hl.window_rule({ match = { class = "Alacritty" }, opacity = "0.90 0.85" })

-- ── Layer rules (DankMaterialShell) ────────────────────────────────────────
-- DMS renders its bar, popups and WALLPAPER on Quickshell layer-shell surfaces in
-- the "quickshell" namespace. On Hyprland a background layer surface is drawn
-- behind windows natively, so the wallpaper "just works" — no swaybg and no niri-
-- style backdrop rule are needed. DMS's own blessed Hyprland rule only disables
-- animations on that layer so the shell doesn't flicker on reload.
hl.layer_rule({ match = { namespace = "^(quickshell)$" }, no_anim = true })

-- ── Autostart ──────────────────────────────────────────────────────────────
-- exec-once equivalent: run on the hyprland.start event.
local function on_start(cmd) hl.on("hyprland.start", function() hl.exec_cmd(cmd) end) end

on_start("dbus-update-activation-environment --systemd --all")
on_start("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
-- Create the XDG user dirs (Documents, Music, Pictures, …) on first login. This config doesn't
-- process /etc/xdg/autostart, so the xdg-user-dirs autostart never fires on its own. Idempotent.
on_start("xdg-user-dirs-update")
on_start("~/.config/kiro-hyprland-dms/scripts/import-gsettings.sh")   -- mirror GTK theme/icons/cursor/font into gsettings
-- The whole desktop: DankMaterialShell (bar, launcher, lock, notifications, wallpaper,
-- control center, session menu, polkit agent). `dms run` starts the Quickshell shell and
-- its backend services — no separate polkit agent / bar / notifier is launched.
on_start("dms run")
-- First-login only: point DMS's wallpaper at the shipped Kiro wallpaper so the desktop is
-- Kiro-branded out of the box (DMS then derives its matugen palette from it). Self-guards on
-- a stamp file, so it is a no-op on every later login and never fights a user's later pick.
on_start("~/.config/kiro-hyprland-dms/scripts/firstrun-wallpaper.sh")
-- Auto-open browsers at login; the window rules above park them on their workspaces/screens.
on_start("firefox")           -- → ws10, left screen
on_start("vivaldi-stable")    -- → ws20, right screen
on_start("opera")             -- → ws19, right screen
-- Live ISO only: auto-launch the installer. archiso-gated; kiro_final strips this line on install.
-- Wrapped in `sh -c` because hl.exec_cmd execs argv directly (no shell) — the `[ ]` test and `&&`
-- need a real shell to be interpreted; a bare string would just try to exec a binary named "[".
on_start("sh -c '[ -d /run/archiso/bootmnt ] && calamares_polkit -d -style kvantum'")

-- ── Keybinds ───────────────────────────────────────────────────────────────
-- bindd-style: every bind carries a description (shown by the keybindings viewer).
local function bind(keys, desc, dispatcher, opts)
  opts = opts or {}
  if desc then opts.description = desc end
  hl.bind(keys, dispatcher, opts)
end
local function run(cmd) return hl.dsp.exec_cmd(cmd) end

-- Apps & session
bind(mod .. " + Return",         "Terminal",         run(term))
bind(mod .. " + T",              "Terminal",         run(term))
bind(mod .. " + SHIFT + Return", "File manager",     run(files))
bind(mod .. " + E",              "Code editor",      run(editor))
bind(mod .. " + B",              "Browser",          run(browser))
bind(mod .. " + V",              "Volume control",   run("pavucontrol"))
bind(mod .. " + Q",              "Close window",     hl.dsp.window.close())
bind(mod .. " + SHIFT + Q",      "Close window",     hl.dsp.window.close())
bind(mod .. " + X",              "Logout menu",      run(logout))
bind(mod .. " + SHIFT + X",      "Power menu",       run(powermenu))
bind(mod .. " + Escape",         "Kill mode",        run("hyprctl kill"))
bind(mod .. " + CTRL + S",       "Show keybindings", run(keybindings))
bind("CTRL + ALT + K",           "Logout menu",      run(logout))
bind(mod .. " + SHIFT + R",      "Reload Hyprland",  run("hyprctl reload"))

-- DankMaterialShell (bar / launcher / lock / wallpaper / settings)
bind(mod .. " + D",              "Launch apps",         run(dms_launcher))
bind(mod .. " + Space",          "Launch apps",         run(dms_launcher))
bind(mod .. " + CTRL + Return",  "Launch apps",         run(dms_launcher))
bind(mod .. " + S",              "Control center",      run(dms_controlpanel))
bind(mod .. " + SHIFT + S",      "Settings",            run(dms_settings))
bind(mod .. " + ALT + L",        "Lock screen",         run(dms_lock))
bind(mod .. " + SHIFT + W",      "Wallpaper browser",   run(dms_wallpaper))
bind(mod .. " + SHIFT + C",      "Clipboard history",   run(dms_clipboard))
bind(mod .. " + SHIFT + N",      "Notification center", run(dms_notifs))

-- CTRL+ALT app launchers (Kiro scheme)
bind("CTRL + ALT + A",       "Alacritty tweak tool", run("alacritty-tweak-tool"))
bind("CTRL + ALT + B",       "Brave",           run("brave --password-store=basic"))
bind("CTRL + ALT + C",       "Chromium",        run("chromium -no-default-browser-check"))
bind("CTRL + ALT + D",       "OBS Studio",      run("obs"))
bind("CTRL + ALT + E",       "Tweak tool",      run("archlinux-tweak-tool"))
bind("CTRL + ALT + F",       "Firefox",         run("firefox"))
bind("CTRL + ALT + G",       "Chromium",        run("chromium -no-default-browser-check"))
bind("CTRL + ALT + H",       "Tweak tool",      run("hyprland-tweak-tool"))
bind("CTRL + ALT + I",       "Kiro ISO builder", run("kiro-iso-builder"))
bind("CTRL + ALT + L",       "Logout settings", run("archlinux-logout --settings"))
bind("CTRL + ALT + M",       "USB image writer", run("mintstick -m iso"))
bind("CTRL + ALT + O",       "Opera",           run("opera"))
bind("CTRL + ALT + P",       "Package manager", run("pamac-manager"))
bind("CTRL + ALT + Q",       "Alacritty tweak tool", run("alacritty-tweak-tool"))
bind("CTRL + ALT + R",       "Lock screen",     run(dms_lock))
bind("CTRL + ALT + Return",  "Terminal",        run(term))
bind("CTRL + ALT + T",       "Terminal",        run(term))
bind("CTRL + ALT + S",       "Tweak tool",      run("fish-tweak-tool"))
bind("CTRL + ALT + U",       "Volume control",  run("pavucontrol"))
bind("CTRL + ALT + V",       "Vivaldi",         run("vivaldi-stable"))
bind("CTRL + ALT + W",       "Fastfetch tweak tool", run("fastfetch-tweak-tool"))
bind("CTRL + ALT + Z",       "Fastfetch tweak tool", run("fastfetch-tweak-tool"))
bind("CTRL + ALT + END",     "System monitor",  run("alacritty --class btop -e btop"))
bind("CTRL + SHIFT + Escape","System monitor",  run("alacritty --class btop -e btop"))

-- Function keys (Kiro scheme)
bind(mod .. " + F1",  "Firefox",      run("firefox"))
bind(mod .. " + F2",  "Code editor",  run("code"))
bind(mod .. " + F3",  "Inkscape",     run("inkscape"))
bind(mod .. " + F4",  "GIMP",         run("gimp"))
bind(mod .. " + F5",  "Meld",         run("meld"))
bind(mod .. " + F6",  "VLC",          run("vlc"))
bind(mod .. " + F7",  "VirtualBox",   run("virtualbox"))
bind(mod .. " + F8",  "File manager", run("thunar"))
bind(mod .. " + F9",  "Virt-manager", run("virt-manager"))
bind(mod .. " + F10", "Spotify",      run("spotify"))
bind(mod .. " + F11", "Launch apps",  run(dms_launcher))
bind(mod .. " + F12", "Launch apps",  run(dms_launcher))

-- Window management
bind(mod .. " + SHIFT + Space", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + F",             "Fullscreen",      hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mod .. " + ALT + F",       "Maximize",        hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mod .. " + P",             "Pseudo-tile",     hl.dsp.window.pseudo())
bind(mod .. " + J",             "Toggle split",    hl.dsp.layout("togglesplit"))
bind(mod .. " + G",             "Toggle group",    hl.dsp.group.toggle())

-- Master layout
bind(mod .. " + I",             "Add master",       hl.dsp.layout("addmaster"))
bind(mod .. " + SHIFT + I",     "Remove master",    hl.dsp.layout("removemaster"))

-- Groups — pull the focused window into the group in that direction, creating one if needed (0.55+)
bind(mod .. " + CTRL + left",  "Into group left",  hl.dsp.window.move({ into_or_create_group = "l" }))
bind(mod .. " + CTRL + right", "Into group right", hl.dsp.window.move({ into_or_create_group = "r" }))
bind(mod .. " + CTRL + up",    "Into group up",    hl.dsp.window.move({ into_or_create_group = "u" }))
bind(mod .. " + CTRL + down",  "Into group down",  hl.dsp.window.move({ into_or_create_group = "d" }))

-- Focus
bind(mod .. " + left",  "Focus left",  hl.dsp.focus({ direction = "l" }))
bind(mod .. " + right", "Focus right", hl.dsp.focus({ direction = "r" }))
bind(mod .. " + up",    "Focus up",    hl.dsp.focus({ direction = "u" }))
bind(mod .. " + down",  "Focus down",  hl.dsp.focus({ direction = "d" }))
bind(mod .. " + H",     "Focus left",  hl.dsp.focus({ direction = "l" }))
bind(mod .. " + L",     "Focus right", hl.dsp.focus({ direction = "r" }))
bind(mod .. " + K",     "Focus up",    hl.dsp.focus({ direction = "u" }))

-- Move / swap window
bind(mod .. " + SHIFT + left",  "Swap left",  hl.dsp.window.swap({ direction = "l" }))
bind(mod .. " + SHIFT + right", "Swap right", hl.dsp.window.swap({ direction = "r" }))
bind(mod .. " + SHIFT + up",    "Swap up",    hl.dsp.window.swap({ direction = "u" }))
bind(mod .. " + SHIFT + down",  "Swap down",  hl.dsp.window.swap({ direction = "d" }))

-- Resize
bind(mod .. " + SHIFT + H", "Shrink width",  hl.dsp.window.resize({ x = -50, y = 0,  relative = true }))
bind(mod .. " + SHIFT + L", "Grow width",    hl.dsp.window.resize({ x = 50,  y = 0,  relative = true }))
bind(mod .. " + SHIFT + K", "Shrink height", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }))
bind(mod .. " + SHIFT + J", "Grow height",   hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }))

-- Mouse drag/resize
bind(mod .. " + mouse:272", "Move window",   hl.dsp.window.drag(),   { mouse = true })
bind(mod .. " + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Workspaces — split 10 + 10 across the two screens (chadwm-style; pinned by the
-- hl.workspace_rule block near the monitor config). code: keys are layout-independent.
--   SUPER + 1..0        → left-screen  workspaces 1..10
--   SUPER + ALT + 1..0  → right-screen workspaces 11..20
-- CTRL = move window (follow), SHIFT = send window (stay). ALT selects the right screen.
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

-- Workspace cycling
bind(mod .. " + period",      "Next workspace",     hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + comma",       "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind(mod .. " + mouse_down",  "Next workspace",     hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + mouse_up",    "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind(mod .. " + TAB",         "Next workspace",     hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad (special workspace)
bind(mod .. " + U",         "Toggle scratchpad",  hl.dsp.workspace.toggle_special("scratchpad"))
bind(mod .. " + SHIFT + U", "Send to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Media & brightness keys (routed through DMS, work while locked)
bind("XF86AudioRaiseVolume",  "Volume up",       run("dms ipc call audio increment 5"),   { locked = true })
bind("XF86AudioLowerVolume",  "Volume down",     run("dms ipc call audio decrement 5"),   { locked = true })
bind("XF86AudioMute",         "Mute",            run("dms ipc call audio mute"),          { locked = true })
bind("XF86AudioMicMute",      "Mic mute",        run("dms ipc call audio micmute"),       { locked = true })
bind("XF86AudioPlay",         "Play / pause",    run("dms ipc call mpris playPause"),      { locked = true })
bind("XF86AudioPause",        "Play / pause",    run("dms ipc call mpris playPause"),      { locked = true })
bind("XF86AudioNext",         "Next track",      run("dms ipc call mpris next"),           { locked = true })
bind("XF86AudioPrev",         "Previous track",  run("dms ipc call mpris previous"),       { locked = true })
bind("XF86MonBrightnessUp",   "Brightness up",   run([[dms ipc call brightness increment 5 ""]]), { locked = true })
bind("XF86MonBrightnessDown", "Brightness down", run([[dms ipc call brightness decrement 5 ""]]), { locked = true })

-- Screenshots
bind("PRINT",           "Screenshot region", run('grim -g "$(slurp)" - | wl-copy'))
bind(mod .. " + PRINT", "Screenshot screen", run("grim - | wl-copy"))
