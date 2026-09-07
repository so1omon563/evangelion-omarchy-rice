# Theme variants

Evangelion Rice keeps identity and presentation separate. Wallpaper affinity
selects NERV, EVA-00 Prototype, EVA-00 Refit, EVA-01, or EVA-02 chroma; a theme
variant resolves that shared palette as Standard Command Center, OLED Blackout,
Tokyo-3 Daylight, or High Contrast. This inheritance model provides every
affinity/variant combination without copied themes or changed wallpaper rules.

Use the **Affinity → Theme treatment** row in MAGI Control Center, or:

```bash
magi-theme-variant list
magi-theme-variant status
magi-theme-variant preview oled
magi-theme-variant revert
magi-theme-variant apply daylight
```

`preview` immediately coordinates theme colors, shell surfaces, Hyprland
borders, and the terminal palette while preserving the committed variant.
Additional previews keep the original rollback point. `revert` restores it;
`apply` commits a selection and clears any preview. Variant state is private
(`0600`) under `~/.local/state/evangelion-rice/theme-variant`.

Standard preserves the existing baseline. OLED uses true-black primary
surfaces; Daylight supplies light surfaces and affinity-specific dark accents;
High Contrast targets at least 7:1 primary text contrast. Automated tests cover
the complete 5 × 4 matrix, seven wallpaper mappings, panels, accents, bar icons,
transaction semantics, and terminal coordination.

Wallpaper Auto affinity remains authoritative. Changing treatment never changes
the wallpaper or active EVA unit, and changing wallpaper retains the treatment.
`magi-affinity palette` reports both dimensions as JSON.
