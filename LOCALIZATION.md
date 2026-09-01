# Localization foundation

English (`en-US`) remains the only production language in v1.5. The runtime
and layouts are prepared for translators, while `qps-ploc` and `ar-XB` are
test-only pseudo-locales for text expansion and right-to-left behavior.

## Catalog and runtime

The canonical versioned catalog is `omarchy/i18n/en-US.json`. Keys describe
meaning (`context.no_action`), never visual position. Placeholders use named
braces such as `{count}` so translators can reorder them. The resolver always
falls back to the key in the English catalog; incomplete future catalogs must
fall back to `en-US`, never an empty string.

```bash
magi-i18n status --json
magi-i18n get context.recommended count=2
magi-i18n set qps-ploc   # expanded accented copy
magi-i18n set ar-XB      # mirrored RTL stress mode
magi-i18n reset          # production en-US
magi-i18n validate
```

Pseudo-locales persist only their locale identifier in a mode-0600 state file.
They do not collect machine or identity data. `NERV`, `MAGI`, `EVA`, `Tokyo-3`,
and `A.T. Field` are protected franchise terms and remain unchanged unless the
project explicitly adopts localized official terminology later.

## Layout rules

- Containers with localized children inherit `LayoutMirroring` from the locale.
- Single-line labels have an explicit width and `elide`; prose uses wrapping.
- Controls must not calculate width from English character counts.
- Icons do not carry meaning without adjacent text or an accessible tooltip.
- Validate at 100%, 135% pseudo-expansion, and RTL before merging new surfaces.
- Dynamic diagnostic values, identifiers, reason codes, and user-provided
  workspace names are data, not catalog strings.

## Dates, numbers, units, and plurals

Use the active Qt locale for user-facing dates, decimal separators, and digit
shaping. Store timestamps as ISO-8601 UTC and convert only at presentation.
Keep values numeric until display; use Unicode `°C`, `%`, and locale-aware
spacing rather than assembling translated sentences around units. New counted
copy gets separate semantic singular/plural keys until an ICU-compatible
message formatter is adopted; never append an English `s` in interface logic.

## Contributing a translation

1. Copy the English catalog without changing keys or `schema_version`.
2. Set the BCP-47 locale and `direction`; preserve every named placeholder.
3. Keep protected terminology unchanged unless documented otherwise.
4. Run `magi-i18n validate` and `python3 tests/localization.py`.
5. Exercise both migrated surfaces at narrow and wide sizes, then include a
   screenshot with no private data (the MAGI demonstration mode is ideal).
6. Document translator and reviewer names in the pull request, not the catalog.

Catalog additions and layout changes belong in the same commit so English,
expansion, and RTL contracts cannot drift apart.
