# Evangelion Omarchy Control Reference

`Super` refers to the Windows key. Press `Super + K` at any time to open
Omarchy's complete live keybinding reference.

## MAGI interfaces

| Shortcut | Action |
|---|---|
| `Super + M` | Open the MAGI Command Interface |
| `Super + Escape` | Open NERV Session Control |
| Power key | Open NERV Session Control |
| `Super + Shift + F12` | Toggle the Tokyo-3 presentation layout |
| `Super + Alt + A` | Toggle AT Field focus mode |
| `Super + Alt + L` | Open NERV classified download intake |
| `Super + Alt + V` | Inspect NERV privacy activity |
| `Super + Alt + T` | Open the MAGI mission timer |
| `Super + Alt + H` | Open the NERV system-health panel |
| `Super + Alt + C` | Open the MAGI world and mission clock |
| `Super + Alt + G` | Open the MAGI context inspector |
| `Super + K` | Show every active Omarchy keybinding |

## Visual systems

| Shortcut | Action |
|---|---|
| `Super + Ctrl + Space` | Open the wallpaper switcher |
| `Super + Shift + Ctrl + Space` | Open the theme menu |
| `Super + Shift + Space` | Toggle the top bar |
| `Super + Ctrl + P` | Open the battery and power-profile panel |
| `Super + Ctrl + N` | Toggle night light |

Choose `MAGI Command Interface → Interface Motion` for Full, Reduced, or Off.
Full preserves the established v1.1 compositor feel. Reduced removes blur,
workspace travel, and window pop/scale while retaining short fades; Off uses
immediate compositor state changes. Capture operations temporarily request the
Reduced profile and restore the selected level afterward.

## Capture operations

| Shortcut | Action |
|---|---|
| `Print` | Interactive screenshot with NERV completion telemetry |
| `Alt + Print` | Start or stop screen recording through the existing Omarchy menu |

The capture keys still use Omarchy's stock selection, annotation, audio,
webcam, cancellation, and finalization paths. During screenshots, the privacy
and `REC` indicator is suppressed just before the screen freezes and restored
on every exit path. Add `--include-indicator` only when you deliberately want
it captured.

```bash
magi-capture screenshot
magi-capture screenshot fullscreen save
magi-capture screenshot fullscreen save --include-indicator
magi-capture recording --fullscreen
magi-capture recording --stop-recording
```

Successful saves show the exact output destination. Cancelled region selection
remains silent and produces no misleading completion confirmation.

The Evangelion wallpaper set includes NERV Command, EVA Unit-01, MAGI
Tokyo-3, Angel Alert, EVA Unit-00 Prototype, EVA Unit-00 Refit, and EVA
Unit-02. The presentation layout automatically selects a left-side safe width
for each composition.

Wallpaper changes also select an EVA Unit Affinity automatically: Unit-00
Prototype uses yellow/orange, Unit-00 Refit uses blue/cyan, Unit-01 uses
purple/green, and Unit-02 uses red/orange. Other wallpapers use the neutral
NERV/MAGI palette. Use `MAGI Command Interface → EVA Unit Affinity` for a
persistent manual override or to return to automatic mode.

### AT Field focus mode

`Super + Alt + A` atomically engages or releases the focus envelope. While
active it suppresses non-critical notifications, darkens the bar, applies an
amber active-window border, and shows `A.T. FIELD // ACTIVE` in the bar. Click
that indicator to release the mode. The prior notification, bar, and border
states are restored exactly; applications and windows are not changed.

```bash
magi-focus toggle   # Engage or release
magi-focus on       # Engage idempotently
magi-focus off      # Release and restore the snapshot
magi-focus status   # Print active or inactive
```

## Communication link

The compact `COMM //` bar readout summarizes internet connectivity, active
route, Wi-Fi signal, NetworkManager VPN, Bluetooth devices, and online
Tailscale peers. Left-click opens the unified telemetry card; right-click
opens the existing Network control. The card links to Omarchy's existing
Network, Bluetooth, and Tailscale panels, so it does not replace their device
management or run another resident service.

Use `MAGI Command Interface → Communication Link`, or inspect the same
snapshot in a terminal:

```bash
magi-communications
magi-communications --json
```

## Privacy activity

The `PRIVACY //` warning appears at the far right whenever the microphone,
camera, screen sharing, recording, or a known remote-control service is active.
It stays visible for the entire active state; click it, press `Super + Alt + V`,
or choose `MAGI Command Interface → Privacy Activity` to see the responsible
applications when PipeWire exposes them.

The response control is deliberately conservative: it mutes the default
microphone, stops Omarchy's known screen recorder, and stops active known user
remote-control services. Camera and portal-based sharing remain under the
responsible application's control, so the panel names the app to close instead
of terminating an arbitrary process.

```bash
magi-privacy status                  # Human-readable active state
magi-privacy status --json           # Machine-readable snapshot
magi-privacy stop all                # Apply the safe response
magi-privacy preview --seconds 30    # Simulate indicators without capturing
```

## MAGI mission timer

Press `Super + Alt + T` or choose `MAGI Command Interface → Mission Timer` to
open the focus-cycle panel. `SORTIE` is ready; `MISSION ACTIVE` counts down a
focus interval; `RECOVERY` counts down the break; and `MISSION COMPLETE` marks
the end of the configured set. Middle-click the bar readout to pause or resume,
and right-click it to abort. State is stored outside the shell process, so bar
reloads do not reset an active or paused mission.

```bash
magi-mission start
magi-mission toggle                   # Pause or resume
magi-mission skip                     # Advance the current phase
magi-mission abort
magi-mission status
magi-mission configure --work 25 --break-minutes 5 --long-break 15 --cycles 4
magi-mission configure --sound off    # Optional completion cues
```

## NERV system health

Press `Super + Alt + H`, click the compact green check beside the privacy
indicator, or choose `MAGI Command Interface → System Health`. The panel
consolidates CPU temperature, memory pressure, home-filesystem capacity,
battery charge and condition, failed user services, network connectivity, and
available updates. The nominal bar state is icon-only; warnings expand into a
labeled alert and include a suggested action in the panel.

Polling is 45 seconds while nominal and 15 seconds during an alert. Package
update checks are cached for 15 minutes. Unsupported sensors are shown as
unavailable and never treated as failures.

```bash
magi-health status
magi-health status --json
magi-health preview --seconds 30
```

## MAGI context inspector

Press `Super + Alt + G`, click the compact context glyph immediately before the
privacy indicator, or choose `MAGI Command Interface → Context Inspector`.
Opening the panel explicitly refreshes the bounded local observations. The
panel shows the selected state, freshness, stable reason, allowlisted
contributing facts, per-capability availability, suppressed alternatives, and
any recommended action. It deliberately does not display a confidence score.

Use Tab and Shift+Tab to move through controls, Enter or Space to activate the
focused control, and Escape to close. Recommendation buttons accept only the
known docked/mobile operating-profile action and are the explicit confirmation;
the inspector never runs an automatic action. Unknown, unavailable, disabled,
and stale states are written plainly. The panel scrolls instead of overflowing
on compact displays and follows the global Full, Reduced, or Off motion mode.

## MAGI world and mission clock

The compact `UTC // HH:MM` readout sits beside the local clock. Press
`Super + Alt + C` or click it for Arizona local time, UTC, selected remote
zones, session uptime, and persistent mission elapsed time. Each remote row
explicitly says `YESTERDAY`, `TODAY`, or `TOMORROW` relative to Arizona.
Middle-click the readout to start or pause mission elapsed time.

Edit `~/.config/omarchy/magi-clock.json` to change labels or IANA timezone
names. Invalid zones appear as unavailable instead of breaking the panel.

```bash
magi-clock status
magi-clock start
magi-clock pause
magi-clock toggle
magi-clock reset
```

## Media controls

Standard hardware media keys continue to work when exposed by the device. MAGI also provides:

| Shortcut | Action |
|---|---|
| `Super + Alt + P` | Play or pause the active source |
| `Super + Alt + N` | Next track |
| `Super + Alt + B` | Previous track |
| `Super + Alt + X` | Stop playback |

When media is available, a compact `AUDIO //` readout appears beside the
workspace labels. Left-click opens artwork, transport controls, and source
selection; middle-click toggles playback; right-click advances; scrolling
moves between tracks. The widget disappears entirely when no source has track
metadata.

## Launchers

| Shortcut | Action |
|---|---|
| `Super + Space` | Open the standard Omarchy menu |
| `Super + Alt + Space` | Open the application menu |
| `Super + Return` | Open a terminal |
| `Super + Shift + Return` | Open the browser |
| `Super + Shift + F` | Open the file manager |

## Workspaces

| Shortcut | Action |
|---|---|
| `Super + 1` … `Super + 5` | Switch to MEL, BAL, CAS, ENTRY, or TERMINAL |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Ctrl + Tab` | Return to the former workspace |
| `Super + Shift + 1` … `Super + Shift + 5` | Move the active window to a workspace |

## Menu controls

| Input | Action |
|---|---|
| Arrow keys | Move the selection |
| `Enter` | Open or activate the selected row |
| `Escape` | Return to the previous menu or close |
| Type text | Search the current interface |
| Pointer hover and click | Select and activate a row |

NERV logout, restart, and shutdown confirmations always select **ABORT**
first. Move to **EXECUTE** deliberately before activating a destructive action.

## Terminal profiles

Use `MAGI Command Interface → Terminal Profile`, or run:

```bash
eva-terminal-profile eva-01       # Purple; desktop default
eva-terminal-profile magi         # Green; diagnostics
eva-terminal-profile engineering  # Orange; maintenance
eva-terminal-profile status       # Print the current profile
eva-terminal-profile list         # List available profiles
```

The profile coordinates Ghostty, Alacritty, Kitty, Foot, Starship, fzf, bat,
lazygit, and compatible Neovim interface accents.

Plain interactive terminal launches are also context-aware. Explicit path
rules are checked first, followed by project markers such as `.git`,
`pyproject.toml`, `package.json`, `Cargo.toml`, `Dockerfile`, or Terraform and
Ansible markers. A match gives only the new terminal an isolated palette and
Starship identity; existing terminals and the global EVA affinity are not
changed. Unknown directories use the normal global terminal profile.

```bash
magi-terminal-context detect --json       # Explain the rule for this directory
magi-terminal-context launch              # Launch an automatically styled terminal
magi-terminal-context launch --profile magi  # Launch with an explicit profile
eval "$(magi-terminal-context env engineering)"  # Override this terminal only
eval "$(magi-terminal-context env auto)"         # Re-detect this directory manually
eval "$(magi-terminal-context env default)"      # Restore the global profile here
magi-terminal-context status              # Show this terminal's effective profile
```

Rules are ordinary JSON in
`~/.config/omarchy/magi-terminal-context.json`. Path rules take precedence and
the most specific matching path wins. Marker rules are evaluated in their
written order while walking from the working directory toward the filesystem
root. No profile command runs on `cd`; detection happens only at terminal
launch or when `magi-profile auto` is explicitly requested.

## Dictation

| Input | Action |
|---|---|
| Hold Right Ctrl | Push-to-talk dictation |
| Release Right Ctrl | Stop dictation and insert text |

## Screenshots and notifications

| Shortcut | Action |
|---|---|
| `Print` | Screenshot |
| `Alt + Print` | Screen recording |
| `Super + Print` | Color picker |
| `Super + Ctrl + Print` | Extract text from a selected region |
| `Super + Comma` | Dismiss the latest notification |
| `Super + Shift + Comma` | Dismiss all notifications |
| `Super + Shift + Alt + Comma` | Open notification history |

## Idle, screensaver, and lock sequence

The desktop moves through three distinct stages when no input is detected:

| Idle time | Stage |
|---|---|
| 3 minutes | Show the lightweight MAGI system-status display |
| 5 minutes | Retire the status display and launch the screensaver |
| 10 minutes | Lock the session; normal display power-down remains available |

Any keyboard or pointer input dismisses the MAGI status display immediately.
Omarchy's **Stay Awake** control suppresses the idle sequence.

For an immediate visual check or troubleshooting:

```bash
omarchy-shell magi-idle show    # Show the MAGI idle display
omarchy-shell magi-idle hide    # Hide it
omarchy-shell magi-idle state   # Print its timers and current state
```

The Evangelion screensaver rotates through MAGI diagnostics, synchronization
telemetry, NERV security typography, and a restrained Unit-01 standby display.
Peripheral telemetry, scene progress, a slow scan sweep, and short feed-routing
transitions provide motion without turning the display into a distraction.
Keyboard input, clicks, scrolling, or pointer movement dismiss it immediately.

```bash
~/.local/bin/omarchy-launch-screensaver force  # Preview it immediately
magi-screensaver-mode default           # Restore the stock Omarchy screensaver
magi-screensaver-mode evangelion        # Re-enable the Evangelion sequence
magi-screensaver-mode status            # Print the selected implementation
```

Create `~/.config/omarchy/evangelion-screensaver.json` with
`{"reduced_motion": true}` for static scenes. The optional `scene_seconds`
number controls scene duration and defaults to 12 seconds.

The three delays are configured in `~/.config/omarchy/shell.json` as
`idle.status`, `idle.screensaver`, and `idle.lock`.

## Login sequence

Once per graphical login, the MAGI startup sequence brings MELCHIOR,
BALTHASAR, and CASPER online before reporting `MAGI SYSTEM // NOMINAL`. It runs
through Omarchy's post-boot hook without delaying access to the desktop.

Use `MAGI Command Interface → Startup Sequence`, or run:

```bash
magi-boot-sequence preview   # Show it immediately
magi-boot-sequence disable   # Disable it with one setting
magi-boot-sequence enable    # Enable it for future graphical logins
magi-boot-sequence status    # Print enabled or disabled
```

## Interface sound cues

Short procedural tones accompany lock, unlock, NERV Session Control, critical
battery, and successful MAGI login. They are synthesized locally—no external
audio assets are bundled—played at 16% stream volume, and rate-limited per cue.
Missing or unavailable audio services never block the related desktop action.

Use `MAGI Command Interface → Interface Sound Cues`, or run:

```bash
magi-sound test      # Preview all five cues
magi-sound disable   # Disable every cue globally
magi-sound enable    # Re-enable cues
magi-sound status    # Print enabled or disabled
```

## Command-line access

## Docked and mobile operating profiles

The operating profile responds to actual output changes—there is no background
polling loop. Automatic mode selects **docked** when any non-laptop display is
active and **mobile** when only `eDP`, `LVDS`, or `DSI` outputs remain. A short
1.4-second settle delay absorbs dock negotiation before applying the profile.

Docked mode extends the first external display to the right, selects the
performance power profile, expands the bar to 30 pixels, prefers external
audio when present, and selects the MAGI Tokyo-3 wallpaper. Mobile mode selects
balanced power, a compact 26-pixel bar, built-in audio, and restores the
wallpaper that was active before docking. Missing displays, sinks, or power
profiles are skipped safely. Windows associated with a disconnected output are
moved to the internal or first remaining display.

Use `MAGI Command Interface → Operating Profile`, or run:

```bash
magi-operating-profile status   # Show mode, detection, and active profile
magi-operating-profile plan     # Preview the effective preferences
magi-operating-profile auto     # Release manual hold; allow recommendations
magi-operating-profile docked   # Persistent manual docked override
magi-operating-profile mobile   # Persistent manual mobile override
magi-operating-profile apply    # Reapply without changing the override
magi-context-automation preview # Explain pending action, cooldown, or hold
magi-context-automation apply --dry-run # Preview without changing anything
magi-context-automation undo    # Restore the pre-automation snapshot
```

Automation remains off until both `magi-context automation-rule
environment_profile enable` and `magi-context automation enable` are selected.
The Operating Profile → Context Automation menu exposes the same controls.
Manual Docked/Mobile selection creates a visible hold; Auto releases it.

Edit `~/.config/omarchy/operating-profiles.json` to change either profile's
`power_profile`, `bar_size`, `audio_target`, `wallpaper`, or `display_layout`.
Use `keep` for audio/wallpaper to leave it unchanged; `restore` is supported for
the mobile wallpaper.

## Umbilical-power transitions

A genuine AC connection or disconnection displays a restrained NERV power card
after a 1.2-second hardware-settle delay. It reports charge percentage and,
when UPower provides a trustworthy estimate, time to full charge or remaining
runtime. The service initializes silently on login and suppresses connector
flapping for ten seconds. Its optional cue follows the global Interface Sound
Cues setting, and `reduced_motion` shortens the display and removes its fade.

Preview either state without changing the actual power source through
`MAGI Command Interface → Umbilical Power Sequence`, or run:

```bash
magi-power-sequence preview ac       # Preview UMBILICAL POWER CONNECTED
magi-power-sequence preview battery  # Preview INTERNAL POWER
magi-power-sequence status           # Inspect live source and rate limiting
magi-power-sequence hide             # Retire the current preview immediately
```

## External-device telemetry

The device OSD listens to udev and live display-list events rather than polling.
It announces USB storage, docks, displays, keyboards, pointing devices, and
audio interfaces while ignoring generic USB churn. Repeated identical events
are suppressed for five seconds. Labels are shortened and serial numbers,
device paths, and vendor IDs are never displayed.

Use `MAGI Command Interface → External Device Telemetry`, or run:

```bash
magi-device-osd preview storage connected  # Preview without a device event
magi-device-osd preview display disconnected
magi-device-osd open       # Open the most recent USB filesystem if mounted
magi-device-osd status     # Show listener state and genuine event count
```

The open action resolves the stored device node through the current mount table
at invocation time and refuses unmounted or invalid targets. It never mounts or
executes content automatically.

## Terminal command-completion telemetry

New interactive Bash sessions notify when a command exceeds the configured
duration threshold. Notifications contain only success/failure, elapsed time,
and numeric exit status. Command text, arguments, history, paths, and output are
never retained or sent. Short commands are ignored, and the hook returns the
original command status before the rest of the prompt cycle runs.

Use `MAGI Command Interface → Command Completion Telemetry`, or run:

```bash
magi-command-telemetry status
magi-command-telemetry disable       # Immediate global disable
magi-command-telemetry enable        # Applies fully to newly opened shells
magi-command-telemetry preview-success
magi-command-telemetry preview-failure 7
```

Configure `threshold_seconds` (default `10`) and optional success cue in
`~/.config/omarchy/command-telemetry.json`:

```json
{ "threshold_seconds": 10, "sound": true }
```

If another tool already owns Bash's DEBUG trap, the integration yields without
replacing it and sets `__MAGI_COMMAND_TELEMETRY_CONFLICT=1` in that shell.

## NERV thermal monitoring

Available Intel, AMD, generic hwmon, or Linux thermal-zone sensors are sampled
every 30 seconds. Normal temperatures remain silent. A warning begins at 85°C and clears below 78°C; a
critical condition begins at 95°C and de-escalates below 88°C. Warning and
critical cooldowns are 20 and 5 minutes respectively, in addition to the state
hysteresis, so a fluctuating workload cannot spam alerts.

```bash
magi-thermal-alert status
magi-thermal-alert preview warning
magi-thermal-alert preview critical
magi-thermal-alert disable
magi-thermal-alert enable
```

Thresholds, recovery bands, cooldowns, and polling interval are explicit in
`~/.config/omarchy/thermal-alerts.json`. Alerts recommend reducing load and
checking cooling and airflow; they do not claim to control device fans. If no
valid temperature sensor exists, checks report `available:false` and generate no warning.

## MAGI clipboard archive

Press `Super + Ctrl + V` to open the classified clipboard archive. Start typing
to search; pinned records are kept at the top while retaining the existing
Omarchy clipboard backend.

| Key | Archive action |
|---|---|
| `↑` / `↓`, `Page Up` / `Page Down` | Navigate records |
| `Enter` | Paste selected record |
| `Shift + Enter` | Copy without pasting |
| `Alt + Enter` | Open a supported link or file |
| `Ctrl + P` | Pin or unpin selected record |
| `Ctrl + H` | Conceal or reveal its preview |
| `Delete` | Remove selected record |
| `Shift + Delete` | Request a confirmed full archive purge |
| `Escape` | Clear search, then close |

Text, links, files, and captured images carry distinct archive classifications.
Concealment affects previews only—the record remains available for deliberate
copying or pasting.

## EVA deployment workspace

Press `Super + Alt + D` or choose `MAGI Command Interface → EVA Deployment`
to assemble the development sortie on workspace 04. The deterministic layout
places the editor and command terminal on the left and your XDG/Omarchy default
browser and telemetry on the right. Triggering deployment again focuses and
reflows the existing mission without creating duplicate windows.

```bash
magi-deployment deploy     # Assemble or focus the mission
magi-deployment focus      # Return to and reflow the active layout
magi-deployment teardown   # Close only windows launched by this deployment
magi-deployment status     # Show workspace, project, and active roles
magi-deployment plan       # Show the effective configuration
```

Create `~/.config/omarchy/eva-deployment.json` to select a project, workspace,
terminal profile, or initial browser URL:

```json
{
  "workspace": 4,
  "project_dir": "/path/to/evangelion-rice",
  "terminal_profile": "engineering",
  "browser_url": "about:blank"
}
```

The prior workspace and terminal profile are restored during recovery. Window
addresses, PIDs, and classes are checked together before anything is closed, so
an unrelated window cannot be mistaken for a mission-launched process.

## Angel intrusion simulation

Press `Super + Alt + I` or choose
`MAGI Command Interface → Angel Intrusion Simulation` to manually enter or
leave the red-alert demonstration. It can never trigger automatically.

```bash
magi-intrusion enter           # Activate the complete simulation
magi-intrusion enter --silent  # Activate without the optional alarm cue
magi-intrusion exit            # SAFE EXIT; restore every captured state
magi-intrusion status          # Print active, inactive, or recovery-required
magi-intrusion preview         # Show only the warning display
```

Activation captures the current wallpaper, terminal profile, affinity mode,
notification/DND setting, and both border gradients before making changes. The
Angel wallpaper, Unit-02 critical profile, restrained static red borders, and
warning display are then applied. Recovery restores the captured values and is
safe to retry after an interrupted transition.

The warning expands once, then settles into a small persistent status capsule;
there is no flashing. The existing `reduced_motion` preference removes the
transition and shortens the expanded warning. Sound follows the global
`magi-sound` setting and can also be disabled specifically in
`~/.config/omarchy/angel-intrusion.json`:

```json
{ "sound": false }
```

Workspace changes briefly identify the active operational channel. The overlay
appears only after an actual transition, replaces itself cleanly during rapid
switching, and retires within 780 ms (480 ms with reduced motion enabled).
Toggle it from `MAGI Command Interface → Workspace Channel OSD`, or run:

```bash
magi-workspace-osd preview 4  # Preview ENTRY PLUG // DEVELOPMENT
magi-workspace-osd disable    # Disable every workspace transition overlay
magi-workspace-osd enable     # Re-enable automatic overlays
magi-workspace-osd status     # Print enabled or disabled
```

The overlay honors `{"reduced_motion": true}` in the Evangelion screensaver
configuration described above.

```bash
omarchy menu keybindings --print  # Print the complete current binding list
omarchy-menu summon magi          # Open the MAGI interface
omarchy-menu summon system        # Open NERV Session Control
magi-presentation                 # Toggle the presentation layout
magi-affinity status              # Report automatic/manual mode and active unit
magi-affinity set unit-02         # Hold a manual affinity across wallpapers
magi-affinity auto                # Resume wallpaper-driven affinity
magi-media status                 # Print the active player and track
magi-media play-pause             # Toggle playback through playerctl
magi-control-reference --print    # Print this guide in the current terminal
```

## NERV browser start page

Run `magi-start-page open` or choose `MAGI Command Interface → NERV Browser
Start Page`. The loopback-only dashboard launches through `omarchy launch
browser`, so it follows the current XDG default—Zen, Chromium, or another
standards-compliant browser—without modification.

It uses no external browser scripts and remains useful offline. Only active
theme tokens, coarse battery/thermal state, current MPRIS media metadata, and
Omarchy's formatted weather status are exposed. Hostnames, usernames, IP
addresses, process lists, file paths, and command-execution endpoints are
absent. Weather refreshes with the dashboard every 30 seconds, caches the last
successful reading, and clearly labels cached data when the link is degraded.
The location follows Omarchy's global setting:

```bash
omarchy weather location                  # Show the current location
omarchy weather location --set "Tempe"    # Set it by name
omarchy weather location --clear          # Return to IP auto-detection
```

The command-console instruments are live rather than decorative. MAGI reaches
consensus from battery, thermal, and network health; System Telemetry shows the
active network interface and proportional battery/temperature meters; Audio
Channel reads player identity, state, track duration, and position through
MPRIS/playerctl. Warning, rejection, paused, cached, and offline states each
shift their panel signaling automatically.

The header rail reports the active EVA affinity, named workspace, operating
profile, uptime, and network state. The Operations Log records state changes
observed while the local dashboard service is running. Unit-00, Unit-01, and
Unit-02 affinity changes alter the ambient background signal automatically;
real battery, thermal, or network failures activate the emergency treatment.

Dashboard-local controls:

| Input | Action |
|---|---|
| `/` | Open the keyboard-driven MAGI page command palette |
| `↑` / `↓`, `Enter`, `Esc` | Navigate, execute, or close the palette |
| `DENSITY // …` | Cycle compact, standard, and full-command layouts |
| Audio `◀◀`, `▶`/`Ⅱ`, `▶▶` | Previous, play/pause, and next via playerctl |
| `PLAYER ↻` | Cycle among currently running MPRIS players |

The density choice persists in browser-local storage. Page media controls use
only allowlisted loopback endpoints, reject foreign browser origins, and cannot
execute arbitrary commands. The staged boot sequence, scan passes, activity
meters, alert flashes, and ambient motion honor the browser's reduced-motion
preference.

## NERV classified download intake

Press `Super + Alt + L`, choose `MAGI Command Interface → Classified Download
Intake`, or run `magi-downloads open`. The terminal console lists recent files
from the configured XDG Downloads directory with classification, age, size, and
source domain when the filesystem recorded one. Full source URLs are never
shown or written to intake history.

Available actions are deliberately narrow: open non-executable files with the
default application, reveal a file, compute and optionally copy its SHA-256,
or move it into `NERV-Archive` after a second confirmation. Executable-like
files are marked red and cannot be opened by the intake tool.

```bash
magi-downloads open          # Interactive classified intake
magi-downloads list          # Print the current recent-file inventory
magi-downloads list --json   # Machine-readable inventory
magi-downloads directory     # Print the resolved Downloads directory
```

Optional settings live in `~/.config/omarchy/magi-downloads.json`:

```json
{
  "directory": "~/Downloads",
  "archive_directory": "~/Downloads/NERV-Archive",
  "max_items": 40,
  "recent_days": 30
}
```

## Project documentation convention

## MAGI update operations

Run `magi-update run` or use `MAGI Command Interface → MAGI System Update`.
The installed `omarchy update` remains authoritative while a compact overlay
reports preparation, snapshot, framework, keys, packages, migrations, hooks,
AUR, tools, cleanup, verification, completion, or failure.

```bash
magi-update run       # Interactive update
magi-update run -y    # Pass Omarchy's unattended flag through unchanged
magi-update status    # Last phase, exit code, recovery command, and log
magi-update log       # Read the preserved full terminal transcript
```

Failed operations show the last phase and its focused recovery command. Full
logs are copied to `~/.local/state/evangelion-rice/update-operation/logs/`.
The wrapper returns the original updater exit code and does not replace package,
migration, snapshot, or restart logic.

Every completed rice ticket should update this reference when it introduces or
changes a shortcut, command, menu action, timer, or other user-visible behavior.
