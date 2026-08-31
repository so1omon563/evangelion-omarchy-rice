# Release notes

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
