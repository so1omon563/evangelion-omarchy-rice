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
  "context": {
    "enabled": true,
    "automation_enabled": false,
    "automation_rules": { "environment_profile": false },
    "decorative_enabled": true,
    "max_age_seconds": 300,
    "collectors": {
      "power": true,
      "thermal": true,
      "displays": true,
      "devices": true,
      "connectivity": true,
      "media": true,
      "time": true,
      "operating_profile": true
    }
  },
  "ambient": {
    "enabled": true,
    "time_enabled": true,
    "mission_enabled": true,
    "quiet_hours": { "start": 22, "end": 7 },
    "location": null
  },
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
- `context`: global v1.3 context processing, automation, decorative-surface,
  freshness, and per-collector preferences. Both global automation and every
  individual rule default off. This preserved configuration is authoritative
  across upgrades.
- `ambient`: optional local-time and explicit mission/focus presentation.
  Location is absent by default and is never inferred.
- `deployment`: workspace, temporary terminal palette, and browser URL.
- `presentation.workspace`: Fastfetch/btop presentation workspace.

```bash
eva-user-config show
eva-user-config terminal
eva-user-config editor
eva-user-config shell
magi-motion status
magi-motion set reduced
magi-context status
magi-context explain
```

## MAGI context foundation

`magi-context` publishes capability-aware local observations for power and
batteries, thermal pressure, displays and dock state, input/audio device counts,
connectivity state, media activity, local time band, and the explicit operating
profile. It deliberately excludes device names, player identities and metadata,
network names and addresses, process/window titles, clipboard data, browser
history, document paths, and other payload content. Published values pass a
strict per-collector field, type, enum, and range allowlist.

```bash
magi-context status --json       # Read current state; does not publish
magi-context surface --json      # Fixed presentation-safe projection
magi-context explain             # Human-readable state and reason
magi-context refresh --json      # Atomically publish the latest request
magi-context disable             # Global kill switch
magi-context enable
magi-context automation enable   # Opt-in; defaults disabled
magi-context automation disable
magi-context decorative disable
magi-context collector media disable
```

Published state lives at
`~/.local/state/evangelion-rice/context/state.json` with mode `0600`. Schema v1
separates signals, normalized facts, derived state, freshness, reasons, and
recommendations. `unknown`, `unavailable`, `stale`, and `disabled` are explicit
contract values. Concurrent refreshes use monotonic request IDs; a superseded
request cannot overwrite newer state. The controller performs no network I/O,
and makes no system changes. Collectors run only for an explicit refresh, in a
bounded four-worker pool with two-second command deadlines; disabled collectors
do not run. Local IPC and sysfs are preferred, so there is no background polling
loop. A transient failure retains a still-fresh cached observation; after
`max_age_seconds` it is marked `stale` with an explicit reason.

### Deterministic context policy

Policy version 1 evaluates only fresh, allowlisted facts. Its precedence is
fixed and inspectable: critical/high thermal or battery safety, elevated or
conservation safety, explicit manual profile selection, offline connectivity,
docked/mobile environment, active media, then nominal context. Higher-priority
states suppress lower ones without deleting them: their stable reason codes are
retained in `policy_state.suppressed_reason_codes`. The selected reason includes
the exact contributing normalized facts and signal groups.

Thermal bands enter at 75/85/95 °C and exit below 70/80/90 °C. Battery bands on
internal power enter at 30/15/7 percent and exit above 35/20/10 percent. These
separate entry and exit boundaries prevent oscillation around a threshold.
Stale inputs never participate in policy; if no fresh facts remain, the result
is explicitly `unknown` with reason `no-fresh-policy-inputs`.

An auto-profile/environment mismatch must be observed twice consecutively
before a recommendation is emitted. Contradictory or matching observations
reset that candidate. Repeated profile recommendations have a five-minute
cooldown. Recommendations always carry a reason, contributing facts, and
`requires_confirmation: true`. A confirmed recommendation remains visible
while the mismatch persists; cooldown prevents a contradictory target from
being immediately reconfirmed. `automatic_actions` is a separate fixed-schema
list and remains empty unless both the global automation switch and the
individual environment-profile rule are enabled. The policy engine itself
never changes the system; the bounded executor accepts only existing `docked`
and `mobile` profile actions.

The bar's compact context glyph opens the responsive inspector. It reads the
shared state rather than detecting anything itself and refreshes collectors only
when the panel is opened or Refresh is explicitly selected. Displayed facts use
a second fixed allowlist; raw signal values and the numeric confidence field are
not rendered. The panel is also available with `Super + Alt + G` or from
`MAGI Command Interface → Context Inspector`.

### Context-aware surfaces

The mode OSD, low-urgency notification borders, start-page status rail, and
screensaver HUD all consume the same read-only `magi-context surface`
projection. They never run collectors or independently inspect hardware. The
projection contains only a fixed status, stable reason code, short label, and
allowlisted contributing facts. Critical notification urgency remains visually
authoritative, and every surface keeps its normal geometry.

Run `magi-context decorative disable` to remove these decorative cues while
leaving context collection and the inspector available. Disabled, stale,
unknown, unavailable, or missing context resolves to `baseline`; in that state
the surfaces match the v1.2 presentation exactly. Re-enable cues with
`magi-context decorative enable` and explicitly refresh from the inspector or
with `magi-context refresh`.

### Ambient operations

`magi-ambient` projects local clock bands plus explicit MAGI Mission and A.T.
Field state into restrained start-page copy and screensaver scene selection.
It does not infer activity, intent, or location, and it never overrides EVA
affinity, safety state, accessibility/motion settings, or manual profiles.

```bash
magi-ambient status --json
magi-ambient disable             # Exact baseline presentation
magi-ambient enable
magi-ambient quiet-hours 22 7    # Local whole-hour boundaries
magi-ambient location 33.4484 -112.0740
magi-ambient clear-location
```

Without an explicit location, fixed local-clock bands are used. Providing
latitude and longitude enables offline sunrise/sunset estimates; the daily
result is cached locally and no network or geolocation service is contacted.
Quiet hours suppress the screensaver copy accent and reduce start-page emphasis.
The resolver runs only when a participating surface already refreshes or starts;
there is no ambient daemon, timer, or hidden polling loop.

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

The Omarchy shell owns popup, overlay, and component-state animation;
Hyprland owns window, layer, and workspace animation. Capability flags in the
resolved token set prevent unsupported blur or transform paths from being
requested. When a capability is absent, the same operation remains available
with a static or shorter transition. Motion mode changes presentation only;
they do not bypass confirmation, lock coverage, or command completion.

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

Operating modes share one fixed, non-interactive transition card near the lower
left edge. Presentation, Deployment, A.T. Field, Angel Intrusion, dock/mobile,
and isolated terminal context report entering, active, exited, or aborted state
without covering the desktop or taking focus. Full adds a small edge acquisition
cue, Reduced uses only a short fade, and Off changes immediately. Deployment
and Presentation roll back partial launches; existing sessions are focused
instead of duplicated. A.T. Field and Angel restore captured state, Angel stays
manual with `magi-intrusion exit` always authoritative, dock changes rescue
windows from removed outputs, and presentation still follows wallpaper-safe
placement.

The MAGI bar uses a shared three-pixel state cue for workspace selection,
playing media, mission activity, privacy capture, system health, Cava
availability, communication faults, battery flow/reserve, and A.T. Field.
Affinity changes reuse a two-pixel workspace edge cue and the bar's palette,
adding no extra widget width. Full and Reduced use a single short opacity/color
transition; Off snaps. Privacy, recording, thermal/health, offline network, and
reserve/critical battery cues are synchronous in every mode. Nominal widgets
do not loop or animate, labels retain their existing bounded/elided geometry,
and Cava remains independently optional with its established process limits.

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
magi-operating-profile auto     # Release manual hold; allow recommendations
magi-operating-profile docked
magi-operating-profile mobile
magi-context-automation preview
magi-context-automation apply --dry-run
magi-context-automation undo
```

Context automation is off by default and requires two explicit opt-ins:

```bash
magi-context automation-rule environment_profile enable
magi-context automation enable
```

Recommendations remain visible while automation is disabled. With both
switches enabled, the operating-profile shell service runs the allowlisted
action after fresh context publication. A manual `docked` or `mobile` selection
creates the visible `manual-profile-selection` hold; select `auto` to release
it. Temporary holds use `magi-context-automation hold REASON` and `release
REASON`.

Each automated change captures power, audio, wallpaper, display, bar, and
active-profile state first. A failed subsystem triggers best-effort rollback
and is named in automation status. The executor deduplicates generations,
enforces a five-minute cooldown, supports read-only preview/dry-run, and keeps
one explicit undo snapshot. `magi-context automation disable` is the global
kill switch and does not remove recommendations.

Terminal rules live in `~/.config/omarchy/magi-terminal-context.json` and may
select `eva-01`, `magi`, or `engineering` by path or marker file without
changing existing terminals. See [HOTKEYS.md](HOTKEYS.md).

## Bar icon treatment

Agents, Bluetooth, Dropbox, and Tailscale use thin adapters around their native
Omarchy widgets. Their original click actions, menus, tooltips, and state logic
remain authoritative; only the fixed NERV frame and shared state palette are
added. The StatusNotifier tray remains native so symbolic icons follow the bar
foreground while full-color vendor icons retain their identity. See
[BAR_ICONS.md](BAR_ICONS.md) for the inventory, implementation paths, and the
per-widget stock fallback procedure.

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
