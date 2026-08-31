# Configuration reference

## Core user configuration

The installer creates and then preserves `~/.config/omarchy/evangelion.json`:

```json
{
  "terminal": "auto",
  "editor": [],
  "shell": "auto",
  "shell_integration": true,
  "project_dir": "",
  "motion": { "mode": "full" },
  "deployment": {
    "workspace": 4,
    "terminal_profile": "engineering",
    "browser_url": "about:blank"
  },
  "presentation": { "workspace": 5 }
}
```

- `terminal`: `auto`, `ghostty`, `alacritty`, `foot`, or `kitty`.
- `editor`: argument array such as `["code", "--wait"]`; empty follows
  `VISUAL`, `EDITOR`, then available console editors.
- `shell`: `auto`, `bash`, `zsh`, or `fish` for launched login shells.
- `shell_integration`: preference for helpers; pass
  `--no-shell-integration` to prevent installer startup-file edits.
- `project_dir`: EVA deployment directory; empty uses the invocation directory.
- `motion.mode`: `full` preserves the current visual feel; `reduced` shortens
  motion and removes blur, repeated movement, and most travel; `off` requests
  immediate state changes from participating v1.2 surfaces.
- `deployment`: workspace, temporary terminal palette, and browser URL.
- `presentation.workspace`: Fastfetch/btop presentation workspace.

```bash
eva-user-config show
eva-user-config terminal
eva-user-config editor
eva-user-config shell
magi-motion status
magi-motion set reduced
```

## Interface motion

Choose `MAGI Command Interface → Interface Motion`, or use:

```bash
magi-motion set full
magi-motion set reduced
magi-motion set off
magi-motion cycle
magi-motion show                 # Resolved mode and named tokens
magi-motion hold screen-share    # Temporarily reduce expensive effects
magi-motion release screen-share # Restore the selected mode
```

The preference is written atomically to preserved `evangelion.json` and takes
effect without logout. Shared definitions live in
`~/.config/omarchy/motion.json`: named durations, delays, easing curves, travel
distances, opacities, scales, and capability flags for each mode. Avoid changing these
unless developing a coordinated motion profile. Invalid or incomplete token
files fall back safely to built-in defaults.

Notifications, workspace/device OSDs, power transitions, update telemetry, and
the intrusion alert follow the effective mode. Full uses the established short
fade and subtle notification scale; Reduced uses a short fade without travel or
scale; Off changes visibility immediately. Critical notifications and intrusion
alerts always appear immediately in every mode, never pulse, and retain their
normal dwell or manual-dismiss behavior. Updating an existing notification
coalesces in place instead of replaying its entrance.

MAGI bar popups use the same effective mode without moving actionable content:
Full adds a single anchor-edge acquisition cue, Reduced shortens the content
fade, and Off keeps the established v1.1 popup fade without extra decoration.
Clipboard and power controls acquire keyboard focus immediately; closing is
logical and immediate even while an entrance is still fading.

Lock coverage is security-first and does not animate: the request is committed
before the compositor lock is queued, and its surface is always opaque. Auth
copy changes immediately while a fixed, non-interactive status rail provides a
short Full-mode cue; Reduced limits this to a brief color fade and Off snaps.
The post-success confirmation dwell is 320ms, 100ms, or 0ms respectively.
Password failures and Escape/Ctrl-U clearing are immediate and never echo the
secret. Logout, reboot, and shutdown keep stationary confirmation menus with
ABORT selected before EXECUTE; motion never arms or invokes an action.

The desktop lifecycle has an explicit ownership order: lock, screensaver, idle
status, then boot decoration. Starting the screensaver retires the idle card;
boot OSDs stop as soon as idle, screensaver, or lock takes ownership. Input
dismisses idle/screensaver immediately and existing lock/display timers remain
authoritative. Full retains the staged boot and screensaver feed, Reduced uses
short/static feedback, and Off emits only the final nominal boot state and
static screensaver scenes. Wake never replays the login sequence.

Wallpaper rendering remains owned by Omarchy's preloaded, aspect-cropped
background service so all outputs reveal the same ready frame without a black
or stretched intermediate. Affinity updates are serialized and debounced:
rapid cycling settles on the final symlink, then shell colors, borders, and the
profile for newly opened terminals commit transactionally. Auto mode announces
the resulting EVA unit only when it changes; manual mode stays authoritative.
Full and Reduced retain Omarchy's supported compositor-safe reveal, while Off
snaps the selected frame immediately. Unknown artwork resolves to neutral, and
the original wallpaper commands, hashes, and licensing metadata are unchanged.

Hyprland consumes the effective mode at reload. Full retains the v1.1 window
pop, border/fade, directional workspace slide, special-workspace travel, and
blur. Reduced keeps only short fades and border feedback. Off disables
compositor animation and blur. Changing the selected mode reloads Hyprland
automatically when an active session is available.

Temporary holds reduce Full to Reduced without overwriting the preference.
Screenshot and recording workflows manage their own `screenshot` and
`recording` holds. Use a short generic reason such as `screen-share`, `game`, or
`presentation` for other expensive/fullscreen work; multiple holds may coexist,
and Full resumes only after the last one is released.

## Browser

Browser selection is deliberately outside `evangelion.json`. Launches use
`omarchy launch browser`, following the current XDG/Omarchy default even after
switching between Zen, Chromium, or another browser.

```bash
xdg-settings get default-web-browser
omarchy launch browser about:blank
```

## Weather and start page

The start page consumes Omarchy's weather status and caches the last valid
response offline. Configure the global location with:

```bash
omarchy weather location
omarchy weather location --set "Tempe"
omarchy weather location --clear
```

The page listens only on `127.0.0.1:8765`; control requests accept allowlisted
loopback origins.

## Operating and terminal profiles

`~/.config/omarchy/operating-profiles.json` defines `docked` and `mobile`
power profile, bar size, audio target, wallpaper, and display layout values.
Unsupported power/audio controls are skipped safely.

```bash
magi-operating-profile plan
magi-operating-profile auto
magi-operating-profile docked
magi-operating-profile mobile
```

Terminal rules live in `~/.config/omarchy/magi-terminal-context.json` and may
select `eva-01`, `magi`, or `engineering` by path or marker file without
changing existing terminals. See [HOTKEYS.md](HOTKEYS.md).

## Thermal, screensaver, and optional integrations

`~/.config/omarchy/thermal-alerts.json` controls thresholds, clear points,
cooldowns, and polling. Keep clear thresholds below alert thresholds.

Screensaver preferences live in
`~/.config/omarchy/evangelion-screensaver.json`; use
`magi-screensaver-mode evangelion|default` to select the implementation.

Run `eva-capabilities` for NetworkManager, Bluetooth, Tailscale, brightness,
power profiles, audio, batteries, sensors, Cava, and Neon availability. Missing
integrations degrade independently. The default `evangelion.cava` widget hides
when Cava is absent. Neon compatibility is explicitly installed only when its
external integration exists:

```bash
./install.sh --apply --components neon-overdrive
```
