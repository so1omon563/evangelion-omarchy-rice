# Evangelion Rice Release Audit

Audit ticket: SO1-337

## Results

- Source validation: scripts, JSON, JSONC, Lua, manifests, and widget references pass.
- Live registry: all Evangelion hotkeys are registered and all custom plugins load.
- Menu actions: 102 actions inspected; no missing Evangelion command targets.
- Hyprland: live configuration reports no errors.
- Persistence: mission timer and elapsed clock survive shell plugin rescans; safety previews restore cleanly.
- Bar density: nominal 1920×1080 layout fits. Worst-case simultaneous mission, privacy, and health alerts retain safety telemetry; multi-channel privacy text was compacted after the stress test.
- Polling: health aggregation overlaps thermal and connectivity snapshots intentionally, but uses 45-second nominal/15-second alert intervals and a 15-minute update cache. No extra resident daemon was introduced.
- Documentation: live custom chords and capture overrides are represented in HOTKEYS.md.
- Packaging: the full seven-wallpaper theme was reconciled from the live theme; staged install, repeat install, and manifest-scoped rollback pass.

## Recovery guarantees

The installer requires explicit `--apply`, creates a new timestamped snapshot,
and changes only paths enumerated in its manifest. Shell integration is a
single guarded source line; it does not replace an existing `.bashrc`.
