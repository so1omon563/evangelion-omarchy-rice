# MAGI media controls

The media and spectrum widgets form one fixed-geometry group immediately after
the workspace labels. Omarchy's native MPRIS service selects the oldest active
non-proxy player, falls back through audible, preferred, metadata-bearing, and
controllable sources, and lets a manual source choice win while it remains
available.

Left-click `AUDIO //` to open the panel. Use Up/Down to select a source, Space
to play or pause, Left/Right for previous or next, `+`/`-` for player volume,
and Escape to close. Pointer transport controls and source rows provide the
same actions. The progress rail, elapsed/duration values, album, state, player,
and volume degrade independently when a player omits an MPRIS capability.

## Artwork privacy

The shipped policy displays local, `file:`, image-provider, and resource artwork
only. It does not download, copy, or persist album artwork, so the suite owns no
artwork cache to retain or clear. Remote HTTP(S) artwork is blocked by default
because fetching it can disclose network metadata to an artwork host. Users may
explicitly opt in by changing `artwork.allow_remote` in the preserved
`~/.config/omarchy/media.json`; `cache: none` remains the only supported policy.

## Cava coordination

Cava reserves stable width beside the media widget while a metadata-bearing
source exists. With the shipped `playing` mode, its process runs only during
active playback and the spectrum becomes a quiet standby rail while paused.
Set `cava.mode` to `always` to visualize whenever media exists, or `off` to hide
it. Missing Cava or MPRIS support hides the unavailable surface without blocking
the shell. Supported values are:

```json
{"cava":{"mode":"playing","paused_behavior":"standby"}}
```

CLI controls use the shell's native active-player arbitration when available
and fall back to Playerctl for compatibility:

```bash
magi-media status
magi-media status --json
magi-media list
magi-media source-next
magi-media source-previous
magi-media source-switch   # transfer playback to the next source
magi-media play-pause
magi-media volume-up
magi-media volume-down
```
