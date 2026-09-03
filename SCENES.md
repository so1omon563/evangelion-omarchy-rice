# MAGI affinity scenes

Affinity scenes coordinate the wallpaper, EVA palette, terminal identity, and
optional sound, ambient, and motion preferences as one previewed transaction.
Open the scene editor from `MAGI Command Interface → Affinity Scenes`, or open
the Control Center with `Super + Ctrl + Alt + S` and press `C`.

Use Up/Down to choose a scene, Enter to create a read-only plan, and `A` to
apply that exact plan. `U` restores the captured pre-scene state. Press `T` to
return to Auto authority, where wallpaper affinity changes synchronize the
matching scene. Manual scene selection remains held until Auto is selected.

Shipped scenes cover NERV Command, EVA-00 Prototype, EVA-00 Refit, EVA-01,
EVA-02, and MAGI Operations. Their definitions live in the preserved,
user-owned `~/.config/omarchy/scenes.json`. Wallpaper values must be plain
filenames and every affinity, terminal, sound, ambient, and motion value is
validated against a fixed allowlist.

## Safety and degradation

Unavailable wallpaper or controller capabilities are reported as degraded and
skipped. A failure from an available component stops the transaction and
restores wallpaper, affinity authority, terminal identity, ambient state,
motion mode, and sound state. Full, Reduced, and Off are supported scene
targets, but `keep` is the shipped default so scenes do not silently override
the user's accessibility choice.

All shipped scenes use `sound: keep`. A custom scene requesting `enabled`
remains blocked until the user separately authorizes scene audio. Applying a
scene never plays a cue, even when authorization exists.

```bash
magi-scene status
magi-scene list
magi-scene preview unit-02
magi-scene apply unit-02 --confirm PLAN_ID
magi-scene undo
magi-scene auto
magi-scene authorize-audio enable   # permits enable requests; plays nothing
magi-scene authorize-audio disable
```
