# Troubleshooting

Begin with read-only evidence:

```bash
./preflight.py --json
./validate.sh
omarchy debug --no-sudo --print
```

## Shell, bar, or plugins

```bash
omarchy restart shell
omarchy-shell -q shell rescanPlugins
journalctl --user --since "10 minutes ago" --no-pager | rg -i 'omarchy-shell|qml|error'
find ~/.config/omarchy/plugins -mindepth 1 -maxdepth 1 -type d -name 'evangelion.*' -print
```

Never edit `/usr/share/omarchy`. Validate `shell.json` with
`jq . ~/.config/omarchy/shell.json`. Old `so1omon.*` directories indicate an
incomplete v1.0 migration; rerun the current shell component.

## Motion modes and dynamic cues

```bash
magi-motion show
magi-motion holds
magi-motion set reduced
omarchy restart shell
hyprctl reload
hyprctl configerrors
```

Full is the default; Reduced removes blur, repeated movement, and most travel;
Off requests immediate state changes. If the interface looks reduced while
Full is selected, inspect `magi-motion holds`: recording, presentation, or
screen-sharing safety can temporarily lower the effective mode. Release only a
hold you recognize with `magi-motion release <reason>`.

Omarchy Shell supplies popup/state animation and Hyprland supplies window and
workspace animation. If either runtime lacks a requested capability, motion
tokens resolve to a static or shorter fallback; controls and final state must
still work. A missing cue is therefore a presentation problem, while a command
that does not reach its final state is a functional bug. Run
`./tests/motion-observe.py` in a live session for an optional observation
report; it restores the mode it found.

## MAGI context and recommendations

```bash
magi-context status --json | jq '{generation,controller,derived_state,reasons,recommendations,automatic_actions}'
magi-context explain
magi-context refresh --json
magi-context-automation status --json
./tests/context-regression.py
```

`unknown` means no policy conclusion is possible; `unavailable` means enabled
collectors could not produce observations; `stale` means cached observations
exceeded `context.max_age_seconds`; and `disabled` reflects an explicit kill
switch. Missing capabilities degrade independently. Stale inputs do not drive
policy or automation.

Recommendations do not imply automation. If a recommendation is visible but
no action occurs, confirm both opt-ins with `magi-context status --json`.
`manual-profile-selection` in `magi-context-automation status --json` is an
intentional hold; run `magi-operating-profile auto` only if you want to release
manual authority. Use `magi-context automation disable` as the global kill
switch and `magi-context-automation undo` to reverse the last successful
automated profile transaction.

To restore the exact v1.2 visual baseline while diagnosing the collector layer:

```bash
magi-context decorative disable
# or disable the controller entirely:
magi-context disable
```

The optional T480 timing check writes aggregate metrics only and restores the
exact context state it found:

```bash
./tests/context-observe.py test-results/context-observation.json
```

## Services and start page

```bash
systemctl --user daemon-reload
systemctl --user --no-pager --full status magi-affinity.path magi-start-page.service
magi-affinity palette
magi-bar-refresh status
magi-bar-refresh

The affinity transaction is already committed when a bar refresh warning is
shown. `magi-bar-refresh` safely retries Omarchy's in-process theme IPC and can
be run repeatedly. If it reports that shell IPC is unavailable, use
`omarchy restart shell` once; the next affinity change will return to the
non-restarting IPC path automatically.
journalctl --user -u magi-start-page.service --since "10 minutes ago" --no-pager
curl --fail http://127.0.0.1:8765/api/status | jq .
curl --fail http://127.0.0.1:8765/api/desktop | jq .
```

The desktop projection should show `affinity.state` as `current` and a
workspace with `available: true`. `stale` means the last bar palette refresh
did not succeed or predates the active affinity publication; run
`magi-bar-refresh`. `unavailable` means the affinity command, Hyprland IPC, or
local backend could not answer. The page keeps its static controls usable and
shows an explicit unavailable label instead of retaining old semantic state.
All page assets are served with `no-store` headers so a normal refresh cannot
combine HTML and JavaScript from different installed versions.

Preflight blocks if another process owns port 8765. Identify it before stopping
anything.

## Wallpaper

```bash
omarchy theme set evangelion
omarchy theme bg next
readlink -f ~/.local/state/omarchy/current/background
(cd theme && sha256sum --check backgrounds.sha256)
```

Neon Overdrive wallpaper controls are unrelated and absent unless selected.

## Weather

```bash
omarchy weather location
omarchy weather location --set "Tempe"
curl --fail http://127.0.0.1:8765/api/status | jq '.weather'
```

Offline mode intentionally shows a cached reading or unavailable state.

## Media and Cava

```bash
playerctl -l
magi-media status
command -v cava
eva-capabilities has cava
cava -p ~/.config/omarchy/plugins/evangelion.cava/cava.conf
```

The media widget hides without an active MPRIS player. The Cava widget hides
when Cava is absent and needs an active PipeWire source/monitor to animate.

## Battery and temperature sensors

```bash
eva-capabilities | jq '{battery,thermal}'
magi-health status
sensors
find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print
```

Battery-less systems are supported. Thermal fallback covers Intel `coretemp`,
AMD `k10temp`/`zenpower`, generic hwmon, and thermal zones.

## Hotkey conflicts

```bash
./preflight.py
hyprctl reload
hyprctl configerrors
rg 'o\.bind\(' hypr/bindings.lua
```

The installer replaces `~/.config/hypr/bindings.lua`; merge personal bindings
into the repository copy before applying. Duplicate custom chords fail
validation. [HOTKEYS.md](HOTKEYS.md) is the authoritative control reference.
