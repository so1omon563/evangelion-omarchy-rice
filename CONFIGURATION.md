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
```

The preference is written atomically to preserved `evangelion.json` and takes
effect without logout. Shared definitions live in
`~/.config/omarchy/motion.json`: named durations, delays, easing curves, travel
distances, opacities, scales, and capability flags for each mode. Avoid changing these
unless developing a coordinated motion profile. Invalid or incomplete token
files fall back safely to built-in defaults.

v1.1 surfaces retain their existing behavior until their v1.2 motion ticket
adopts the controller. This prevents installing the foundation alone from
silently changing an established desktop.

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
