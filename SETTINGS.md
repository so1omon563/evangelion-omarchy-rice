# MAGI Control Center

Press `Super + Ctrl + Alt + S`, or choose **MAGI Control Center** from the MAGI
menu, to open the unified settings surface. This chord is intentionally outside
Omarchy's stock bindings; `Super + K` remains the authoritative live reference.

The control center covers ten categories: EVA affinity, motion, operating
profile, widgets, ambient weather, media, privacy, sound, and display. Its
choices come from `settings-schema.json`, not duplicated UI logic. It reports a
missing dependency as unavailable and leaves the existing configuration intact.
The privacy indicator is visibly locked on because capture safety cannot be
disabled here.

The Visual category exposes bounded density, accent strength, typography,
panel treatment, blur, opacity, gaps, borders, and animation intensity. These
values are preserved in `~/.config/omarchy/visual.json`; see
[VISUAL_CUSTOMIZATION.md](VISUAL_CUSTOMIZATION.md). Reduced and Off motion
continue to override visual blur and travel requests.

## Keyboard workflow

Use Up/Down or J/K to move, Left/Right or H/L to select a target value, and
Enter to generate a read-only preview. The preview names the current value, the
new value, and expected effects. Press `A` to apply that exact preview, or move
away to discard it. Press `U` to undo the last control-center change, `R` to
refresh live values and capabilities, and Escape to close.

Apply first captures a selective named snapshot with `magi-snapshot`. The
preview's plan ID must still match when `A` is pressed, preventing a stale or
altered plan from being activated. Undo restores that snapshot through the same
validated snapshot contract. Existing suite configuration remains compatible;
there is no second settings database.

The interface follows Full, Reduced, and Off motion modes. It is fully
keyboard-navigable and does not require hand-editing JSON. The equivalent
diagnostic commands are:

```bash
magi-settings status
magi-settings preview motion.mode reduced
magi-settings apply motion.mode reduced --confirm PLAN_ID_FROM_PREVIEW
magi-settings undo
```

Press `C` from the Control Center to open the affinity scene editor. Scene
selection has its own preview, atomic apply, undo, Auto-authority, capability,
and audio-interlock contract documented in [SCENES.md](SCENES.md).
