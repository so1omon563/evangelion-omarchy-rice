# Bar icon unification

The Evangelion bar keeps Omarchy's upstream implementations and wraps selected
widgets in shared NERV chrome. The adapter loads from `$OMARCHY_PATH`, forwards
the bar and settings objects, and delegates `open`, `close`, and `toggle` to the
native widget. This retains upstream click bindings, panels, tooltips, IPC, and
live status behavior without copying vendor code into this repository.

| Surface | Installed ID | Native implementation | Treatment |
| --- | --- | --- | --- |
| Agents | `evangelion.agents` | `omarchy.agents` | NERV frame; native agent glyph and panel |
| Bluetooth | `evangelion.bluetooth` | `omarchy.bluetooth` | NERV frame; native radio states and panel |
| Dropbox | `evangelion.dropbox` | `omarchy.dropbox` | NERV frame; vendor mark remains recognizable |
| Tailscale | `evangelion.tailscale` | `omarchy.tailscale` | NERV frame; vendor mark remains recognizable |
| StatusNotifier tray | `omarchy.tray` | Omarchy tray | Symbolic icons inherit bar foreground; full-color vendor artwork is preserved |

The shared palette uses accent for normal/hover/active, amber for attention,
and the bar urgent color for errors. Frames have fixed minimum geometry; color
and opacity change without moving neighboring widgets. The stock tray already
recolors symbolic icons and deliberately leaves full-color StatusNotifier
artwork intact, so it stays upstream rather than being forked or recolored.

## Compatibility and fallback

The adapters require the corresponding first-party Omarchy plugin beneath
`$OMARCHY_PATH/shell/plugins`. Run `./preflight.py` before installation after a
major Omarchy upgrade. If an upstream widget moves or changes incompatibly,
replace its `evangelion.*` ID in `~/.config/omarchy/shell.json` with the native
ID shown above and restart the shell. This is a per-widget fallback; the rest of
the theme remains active.

Because all source lookup is based on `$OMARCHY_PATH`, no username, home path,
screen name, or machine-specific path is embedded in the adapters.
