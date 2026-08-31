# Evangelion Omarchy Rice

[![MAGI Integrity Check](https://github.com/so1omon563/evangelion-omarchy-rice/actions/workflows/validate.yml/badge.svg)](https://github.com/so1omon563/evangelion-omarchy-rice/actions/workflows/validate.yml)

Complete Neon Genesis Evangelion desktop environment for Omarchy, including
seven wallpapers, EVA affinity palettes, MAGI shell plugins, safety telemetry,
workspace identities, terminal profiles, menus, sounds, and operational tools.

![Evangelion Omarchy desktop](media/desktop-hero.png)

## Gallery

| MAGI start page | Session controls |
|---|---|
| ![MAGI start page](media/start-page.png) | ![NERV session controls](media/session-menu.png) |

| Lock screen | Terminal profile switching |
|---|---|
| ![MAGI lock screen](media/lock-screen.png) | ![MAGI terminal profiles](media/profile-switching.gif) |

![Seven included wallpapers](media/wallpaper-gallery.png)

> Unofficial fan project. Not affiliated with or endorsed by the owners of
> *Neon Genesis Evangelion*. See [ASSETS_LICENSE.md](ASSETS_LICENSE.md) before
> redistributing wallpaper assets.

## Install

This release targets Omarchy with Hyprland. Before changing any configuration,
run the read-only compatibility preflight:

```bash
./preflight.py
```

Use `./preflight.py --json` for machine-readable results. The preflight does
not create probes or modify configuration; it inspects versions, session state,
dependencies, target permissions, backup capacity, services, port 8765,
hotkeys, displays, terminals, browser, battery, thermal, audio, and networking.
It exits non-zero only when installation would be unsafe or unsupported.

The report separates three levels:

- **Required** — source-validation tools and the active Omarchy desktop. The
  installer stops before its first write if one is missing.
- **Recommended** — a supported terminal plus Fastfetch and btop provide the
  complete reference experience, but are not required for the base theme.
- **Optional** — feature-specific integrations such as media controls, Cava,
  Tailscale, clipboard actions, power profiles, and multi-monitor screensaver
  IPC. A missing optional tool disables only its listed integration.
- **Development** — tooling used to validate and contribute to the repository,
  but not by the installed desktop at runtime.

Every missing group includes an actionable Arch/Omarchy package command. The
canonical machine-readable inventory is [dependencies.tsv](dependencies.tsv).
Preview the default installation without changing target files:

```bash
./install.sh --dry-run
```

Choose a preset or an explicit component list, then apply it:

```bash
./install.sh --apply --preset minimal
./install.sh --apply --preset default
./install.sh --apply --preset full
./install.sh --apply --components theme,tools,shell
```

`minimal` installs the theme and MAGI tools. `default` adds Omarchy shell,
Hyprland, start-page, and service integration. `full` adds Fastfetch, Neovim,
and detected-shell startup integration. Run `./install.sh --list-components` for the
complete selectable list.

### User configuration

The default install creates `~/.config/omarchy/evangelion.json` once and never
overwrites it on later runs. Set `terminal` to `ghostty`, `alacritty`, `foot`,
or `kitty`, or leave it as `auto` to follow `xdg-terminal-exec`. Set `editor`
as a JSON argument array such as `["code", "--wait"]`; an empty array follows
`VISUAL`, `EDITOR`, then available console editors. `project_dir` defaults to
the directory where deployment is invoked, and the browser always launches
through `omarchy launch browser` so the current XDG default is honored.

The full preset detects Bash, Zsh, or Fish. Override with `--shell fish`, or
disable all startup-file integration explicitly with `--no-shell-integration`.
Generated configuration and startup-file changes are included in the same
transaction manifest and are preserved or removed by rollback.

### Optional hardware and integrations

Run `eva-capabilities` for a JSON report of batteries, thermal sensor families,
NetworkManager, Bluetooth tooling, Tailscale, brightness controls, power
profiles, audio, Cava, and Neon Overdrive. Intel `coretemp`, AMD `k10temp` or
`zenpower`, generic hwmon devices, and thermal-zone fallbacks are supported.
Battery-less systems report battery telemetry as unavailable; multiple
batteries are aggregated safely.

Neon Overdrive is not part of any preset and is absent from the default bar.
Its menu appears only when that theme's `neon-control` integration is detected.
Existing users can request the compatibility widget with
`--components neon-overdrive`; its included Cava configuration remains disabled
until Cava is explicitly enabled in Neon Overdrive settings. Missing networking,
Bluetooth, VPN, brightness, audio-routing, or power-profile tools affect only
their corresponding optional controls.

The installer completes preflight before its first backup or write, prints the
exact change plan, and requires confirmation before replacing complete files.
Each transaction snapshots only changed paths under
`~/.local/state/evangelion-rice/install-backups/`. An activation or validation
failure automatically restores that transaction. Repeated installation skips
unchanged files. Use `--yes` only for reviewed, non-interactive automation.

## Validate

```bash
./validate.sh
```

Validation is non-destructive. It checks scripts, JSON, Lua, custom hotkeys,
the dependency manifest, widget sources, live binaries, the bar layout, and
Hyprland configuration. CI can check only repository tooling with
`./check-dependencies.sh --source-only`.

## Compatibility

| Component | Supported | Currently verified |
|---|---|---|
| Omarchy | `>=4.0.0, <5.0.0` | 4.0.1-1 |
| Hyprland | `>=0.56.0, <0.57.0` | 0.56.2-1 |
| Architecture | x86_64 | ThinkPad T480, x86_64 |
| Session | Wayland + active Hyprland IPC | Omarchy/Hyprland |
| Display | Reported dynamically; responsive-layout work remains | 1920×1080 at 1× |
| Terminal | Ghostty reference; Alacritty, Foot, and Kitty detected | Ghostty |
| Browser | XDG default via `omarchy launch browser` | Zen |
| Shell | Bash integration currently provided | Bash |

“Supported” describes the preflight gate, not a claim that every hardware and
display combination has been tested. Verified environments will be added here
as clean-user and external beta testing expands the matrix.

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
