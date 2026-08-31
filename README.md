# Evangelion Omarchy Rice

[![MAGI Integrity Check](https://github.com/so1omon563/evangelion-omarchy-rice/actions/workflows/validate.yml/badge.svg)](https://github.com/so1omon563/evangelion-omarchy-rice/actions/workflows/validate.yml)

Complete Neon Genesis Evangelion desktop environment for Omarchy, including
seven wallpapers, EVA affinity palettes, MAGI shell plugins, safety telemetry,
workspace identities, terminal profiles, menus, sounds, and operational tools.

> Unofficial fan project. Not affiliated with or endorsed by the owners of
> *Neon Genesis Evangelion*. See [ASSETS_LICENSE.md](ASSETS_LICENSE.md) before
> redistributing wallpaper assets.

## Install

Review the repository, then run:

```bash
./install.sh --apply
```

The installer snapshots every file it manages before changing it, records the
snapshot under `~/.local/state/evangelion-rice/install-backups/`, installs the
theme and integrations, activates the user services, and runs validation.
Running it again is supported and creates a new rollback point.

## Validate

```bash
./validate.sh
```

Validation is non-destructive. It checks scripts, JSON, Lua, custom hotkeys,
widget sources, live binaries, the bar layout, and Hyprland configuration.

## Roll back

Restore the most recent installation snapshot:

```bash
./rollback.sh
```

Or provide a specific snapshot directory. Rollback only restores or removes
paths listed in that snapshot's manifest.

See [HOTKEYS.md](HOTKEYS.md) for the full control reference and [AUDIT.md](AUDIT.md)
for release verification.

## License

Software and configuration source are available under the MIT license. Image
assets are excluded from that grant; see [ASSETS_LICENSE.md](ASSETS_LICENSE.md)
and [theme/ARTWORK.md](theme/ARTWORK.md).
