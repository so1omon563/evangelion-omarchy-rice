# Choose and maintain an installation channel

Evangelion Rice has three supported ownership channels. Pick one before
installing; combining channels does not unlock additional features.

| Goal | Channel | What it installs | Best for |
|---|---|---|---|
| Just the look | Omarchy theme gallery/Git theme | Palette, app theme fragments, and seven wallpapers | Users who want native Omarchy theming without MAGI |
| Complete MAGI desktop | Tagged release archive | Theme, tools, shell, Hyprland integration, start page, and selected services | Most users who want the whole experience |
| Follow development | Git checkout | The same suite payload, from a mutable source checkout | Contributors and testers |
| Managed system package | Arch package | Immutable source under `/usr/share/evangelion-rice`; user activation remains explicit | Arch users who want pacman ownership |

MAGI plugins are suite-internal components in v1.4. They are not standalone
marketplace products and must not be copied or advertised as independently
installable plugins. `MAGI_RUNTIME.md` defines a future architectural boundary,
not a published runtime package or supported fourth channel.

## Common prerequisites, capabilities, limitations, and support

All channels require an existing Omarchy installation. The complete suite
supports Omarchy `>=4.0.0,<5.0.0`, Hyprland `>=0.56.0,<0.57.0`, and x86_64.
Suite activation runs as the desktop user in an active Wayland/Hyprland session.
Run `./preflight.py --json` for capabilities and blockers; optional hardware,
MAGI context, Cava, media, weather, and sensor integrations degrade or hide when
unavailable. See `INSTALL.md` for packages and `README.md` for the tested matrix.

Support covers the published channel workflows and version ranges. Local edits,
third-party shell forks, unsupported Omarchy/Hyprland versions, vendor hardware
tools, and mixed ownership are best-effort. Bug reports should include preflight
and validation output, the selected channel/version, and redacted reproduction
steps—never private desktop state.

## Just the look: theme channel

```bash
omarchy theme install https://github.com/so1omon563/omarchy-evangelion-theme.git
omarchy theme set evangelion
omarchy theme bg next
```

Use Omarchy's normal theme update flow to update the Git clone. To remove it,
select another theme first, then remove only the Evangelion theme clone. This
channel cannot provide MAGI widgets, workspace identities, commands, motion,
start page, services, or affinity automation.

The theme and suite both own `~/.config/omarchy/themes/evangelion`. The suite
installer refuses to merge into a Git-owned theme clone. Switch away and remove
the standalone clone before moving to the suite.

## Complete suite: tagged release archive

Download the archive and matching `.sha256` from the GitHub release, then:

```bash
sha256sum --check evangelion-omarchy-rice-1.4.0.tar.gz.sha256
tar -xzf evangelion-omarchy-rice-1.4.0.tar.gz
cd evangelion-omarchy-rice-1.4.0
./scripts/build-release verify-root .
./preflight.py
./install.sh --dry-run --preset default
./install.sh --apply --preset default
omarchy theme set evangelion
./validate.sh
```

Use `minimal`, `default`, `full`, or explicit components as documented in
`INSTALL.md`. Upgrade by downloading and verifying the new exact release, then
previewing and applying the same selection. Each apply records an exact snapshot:

```bash
./rollback.sh /path/printed/by/install
```

For removal, roll transactions back newest to oldest as described in
`UPGRADING.md`. There is deliberately no recursive uninstall command.

## Development checkout

```bash
git clone git@github.com:so1omon563/evangelion-omarchy-rice.git
cd evangelion-omarchy-rice
git status --short
./preflight.py
./install.sh --dry-run --preset default
./install.sh --apply --preset default
```

Before updating, preserve local work and use `git pull --ff-only`. Preview and
apply the same component selection. Rollback/removal semantics are identical to
the release archive. A checkout tracks moving development source, so ordinary
users should prefer a tagged archive.

## Managed Arch package

After installing the package with pacman or an AUR helper, activate it explicitly
as the desktop user:

```bash
evangelion-rice preflight
evangelion-rice plan --preset default
evangelion-rice apply --preset default
evangelion-rice status
```

Pacman owns only immutable system files; it never mutates a home directory.
Use `evangelion-rice rollback`, then remove the package through pacman when
leaving this channel. Full setup, upgrade, deactivation, and removal commands
are in `ARCH_PACKAGING.md`.

## Switching channels

Do not layer multiple owners over the same files. Theme → suite requires removing
the inactive Git theme clone. Git/archive → Arch requires rolling back user
activation before installing and explicitly activating the package. Arch →
Git/archive requires deactivation and package removal first. The tested matrix,
conflict behavior, and CI evidence are in `CROSS_CHANNEL.md`.
