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

## Services and start page

```bash
systemctl --user daemon-reload
systemctl --user --no-pager --full status magi-affinity.path magi-start-page.service
journalctl --user -u magi-start-page.service --since "10 minutes ago" --no-pager
curl --fail http://127.0.0.1:8765/api/status | jq .
```

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
