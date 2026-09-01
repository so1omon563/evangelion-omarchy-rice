# Release notes

## v1.4.0 — distribution and packaging

v1.4 makes the project consumable beyond the reference laptop without splitting
the coordinated MAGI desktop into misleading standalone pieces. Users can now
choose a declarative theme-only repository, a reproducible complete-suite
release archive, a development checkout, or an Arch package with explicit
per-user activation. MAGI plugins remain suite-internal components; the optional
runtime specification is an architectural boundary, not a published package.

The standalone theme is prepared for the official Omarchy gallery and links
back to the complete experience. Complete-suite archives are built from exact
tags with deterministic metadata, checksums, internal manifests, provenance,
and an allowlisted payload. The Arch design keeps pacman-owned files under
`/usr/share` and never mutates a user's home during package installation.

Cross-channel tests cover ownership collisions, theme-to-suite refusal, exact
v1.3 upgrade behavior, forced partial-failure rollback, release and Arch
lifecycles, and the browser, motion, privacy, responsive, Omarchy, and optional
MAGI fallback baselines. CI retains machine-readable ownership evidence.

Start with [DISTRIBUTION_GUIDE.md](DISTRIBUTION_GUIDE.md). Maintainers should use
[MAINTAINING.md](MAINTAINING.md) for synchronization, privacy-reviewed media,
gallery review, exact-candidate CI, and release checklists. Existing v1.3.1
installations upgrade transactionally with the same preset or component list;
personal `evangelion.json` remains preserved and rollback restores the exact
pre-upgrade files.

## v1.3.1 — start-page and affinity stabilization

v1.3.1 is a narrowly scoped stabilization release on the v1.3 baseline. Native
and symbolic bar icons now follow the active EVA affinity without white halos,
while meaningful active, warning, urgent, and full-color vendor states remain
intact. Affinity changes push the live palette through Omarchy's supported
in-process theme IPC; the bar is not restarted. `magi-bar-refresh` remains an
idempotent manual recovery path with structured status and actionable failure.

The local NERV start page now reports Auto/Manual affinity, exact EVA identity,
palette freshness, the configured MAGI workspace label, and operating profile.
A privacy-bounded loopback projection updates these semantic fields every two
seconds without collecting window titles, application names, paths, hostnames,
or workspace contents. Full weather, media, and hardware telemetry retains its
slower cadence.

Zen exposed a mixed-cache upgrade failure in which new HTML and older
JavaScript—or the reverse—could be combined. Static and API responses now use
no-store headers, JS/CSS URLs are versioned, and the renderer tolerates the
older HTML shape. The release gate reproduces both bundle directions and runs
an exact v1.3.0 install, v1.3.1 upgrade, upgrade rollback, repeated upgrade, and
uninstall-equivalent rollback.

The refreshed 1600×900 start-page image uses fictional `?demo=1` telemetry,
contains no browser chrome or live private activity, and has no metadata chunks.
Upgrade and rollback instructions follow below and in
[UPGRADING.md](UPGRADING.md).

## v1.3.0 — MAGI intelligence and context

v1.3 adds a local, capability-aware context contract for aggregate power,
thermal, display, device-count, connectivity, media-state, time, and explicit
operating-profile facts. A deterministic policy publishes stable reasons,
contributing facts, freshness, suppressed alternatives, and recommendations.
It does not collect content, names, addresses, identities, paths, titles, or
browser/clipboard history, and it performs no network I/O.

The new context inspector answers what MAGI concluded and why. Existing OSD,
notification, start-page, and screensaver surfaces consume a fixed decorative
projection and fall back exactly to the v1.2 presentation for stale, missing,
unknown, unavailable, or disabled context. Local time and explicit mission/focus
state can add restrained ambient copy without inferring location or intent.

Recommendations remain advisory by default. Environment-profile automation is
restricted to the existing docked/mobile actions and requires both a global and
per-rule opt-in. Manual selection wins, while preview, dry-run, cooldown,
transaction rollback, failed-subsystem reporting, undo, and a kill switch keep
the operator authoritative.

Agents, Bluetooth, Dropbox, and Tailscale retain their upstream implementation
behind transparent adapters. Native glyphs and symbolic tray icons share a
dedicated resting foreground without per-widget frames; wallpaper affinity
selects gold, ice blue, violet, coral, or neutral lavender independently of
general panel text. Meaningful active, warning, and urgent colors remain
native. Full-color vendor tray artwork keeps its identity.

Affinity now reapplies the live shell palette through supported Omarchy IPC,
without restarting the bar. An idempotent `magi-bar-refresh` command and EVA
Unit Affinity menu action provide explicit recovery when the shell is absent or
temporarily unavailable.

The v1.3 suite adds schema migration, process restart, killed-refresh,
latest-request convergence, private-sentinel, and optional state-restoring live
performance coverage. On the T480, 12 refreshes measured 158.75 ms mean,
167.59 ms p95, and 168.35 ms maximum; a three-second idle observation saw no
context process and no context-state writes.

Upgrade and exact rollback steps are in [UPGRADING.md](UPGRADING.md). The
synthetic context comparison in `media/context-states.png` contains no live
telemetry. External hardware feedback remains welcome but optional after
release.

## v1.2.0 — dynamic MAGI interface

v1.2 adds one coordinated motion system without changing the stable v1.1
layout. Full, Reduced, and Off modes now govern shared motion tokens across the
shell, panels, overlays, lock lifecycle, operating-profile transitions,
workspace/device cues, wallpaper affinity, and restrained bar
microinteractions. Full remains the default. Reduced shortens transitions and
removes blur, repeated movement, and most travel; Off requests immediate state
changes wherever the compositor or shell permits.

The implementation is defensive: lock coverage is immediate and opaque,
destructive actions remain confirmation-gated, rapid mode changes converge on
the latest request, and missing compositor or shell capabilities fall back to
static presentation. Recording, presentation, and other temporary holds reduce
expensive effects without changing the user's saved preference.

Upgrade from v1.1 with the same preset previously installed. The installer
preserves `~/.config/omarchy/evangelion.json`, including `motion.mode`, and
installs the coordinated token profile at `~/.config/omarchy/motion.json`.
See [UPGRADING.md](UPGRADING.md), [CONFIGURATION.md](CONFIGURATION.md), and
[TROUBLESHOOTING.md](TROUBLESHOOTING.md). The Full and Reduced demonstrations
in `media/` use synthetic interface state on the MAGI standby surface and were
reviewed for private content before publication.

## v1.1.0 — portable release

This candidate turns the original machine-specific rice into a portable,
transactional Omarchy package. It adds read-only compatibility preflight,
presets and component selection, clean-user lifecycle tests, responsive layout
profiles, explicit dependency and support contracts, safe rollback, and public
installation, configuration, troubleshooting, upgrade, and testing guides.

The public plugin namespace is now `evangelion.*`. Existing `so1omon.*` plugin
directories are migrated transactionally during installation and restored by
rollback. Personal settings in `~/.config/omarchy/evangelion.json` are
preserved. Cava is available independently as `evangelion.cava`; Neon
Overdrive remains an optional compatibility component.

Before upgrading, read [UPGRADING.md](UPGRADING.md), run `./preflight.py`, and
review `./install.sh --dry-run` with the intended selection. Every applied
transaction prints and records its rollback snapshot.

The supported matrix is based on the reference Omarchy system plus isolated
clean-user, hardware-capability, and responsive-layout simulations. It does not
claim verification on every physical hardware combination. Community reports
are welcome through [BETA_TESTING.md](BETA_TESTING.md) and will inform future
compatibility updates.
