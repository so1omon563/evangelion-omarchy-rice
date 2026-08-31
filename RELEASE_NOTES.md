# Release notes

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
behind shared NERV icon chrome. The native tray continues to recolor symbolic
icons while preserving full-color vendor identity.

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
