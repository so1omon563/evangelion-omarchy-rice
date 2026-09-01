# Evangelion for Omarchy

An unofficial, non-commercial Evangelion-inspired theme for Omarchy. It uses a
dark Tokyo-3 command-center palette with EVA-01 purple, acid green, NERV red,
and safety orange, plus seven coordinated wallpapers.

## Install

Once the dedicated theme repository is published:

```bash
omarchy theme install https://github.com/so1omon563/evangelion-omarchy-theme.git
```

The repository name resolves to the theme slug `evangelion`. Installation
applies the theme; switch back later with `omarchy theme set <another-theme>`.

Cycle its wallpapers with:

```bash
omarchy theme bg next
```

This package contains only declarative theme files and images. It does not
include the MAGI widgets, commands, Hyprland configuration, start page, or user
services from the complete Evangelion Rice suite.

## Requirements

- A current Omarchy installation
- Git, as used by `omarchy theme install`
- An Omarchy shell version that supports split `shell.*.toml` theme fragments

## Updates and removal

Omarchy can update a Git-installed theme through its normal theme update flow.
To remove it, first select another theme, then remove only the cloned
`~/.config/omarchy/themes/evangelion` directory. No unrelated configuration is
owned by this package.

## Licensing

Software/configuration is MIT-licensed. Wallpaper terms and provenance are in
`ASSETS_LICENSE.md` and `ARTWORK.md`. Evangelion names, designs, and marks
remain the property of their respective rights holders; no endorsement or
commercial-use permission is implied.
