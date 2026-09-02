# Safe visual customization

The MAGI Control Center exposes nine bounded visual controls without requiring
manual JSON edits: density, accent strength, typography, panel treatment,
blur, window opacity, gaps, borders, and animation intensity. Open it with
`Super + Ctrl + Alt + S`, select a Visual row, choose with Left/Right, press
Enter to preview, and press `A` to apply. `U` restores the pre-apply snapshot.

Values live in the preserved user-owned file
`~/.config/omarchy/visual.json`. The installer never mutates packaged Omarchy
files. Compact/standard accessibility defaults remain bounded, and invalid or
unknown values are rejected before any file changes.

Compositor controls reload Hyprland when it is available. If it is unavailable,
the selection is saved and reported as degraded so it can apply at the next
Hyprland session. Reduced and Off motion remain authoritative: they disable
travel and/or blur even when a visual token requests stronger treatment.

```bash
magi-visual status --json
magi-visual set density compact
magi-visual set blur subtle
magi-visual reset
magi-settings undo
```

`magi-visual reset` restores the shipped visual baseline. Control Center apply
is preferred because it creates the selective snapshot used by one-step undo.
