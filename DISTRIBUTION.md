# Distribution contract

This document defines the v1.4 packaging boundaries. It is normative: a
package or catalog submission must fit one tier below and must not acquire the
ownership rights of a broader tier merely because the files share a repository.
The machine-readable companion is [`distribution.json`](distribution.json).

## Distribution matrix

| Tier | Intended channel | Owned payload | Activation | Updates and rollback | Removal |
|---|---|---|---|---|---|
| Theme | Omarchy theme catalog or theme Git repository | `theme/` copied as one named theme | User selects `evangelion`; it never edits the active theme implicitly | Replace only files inside the named theme directory; previous version or package-manager cache supplies rollback | Remove the named theme only when it is inactive; retain unrelated themes and user config |
| Plugin | Omarchy plugin catalog or one plugin Git repository | One audited `evangelion.*` plugin directory plus declared runtime/API dependencies | Explicit plugin install and explicit bar/service enablement | Semantic plugin version; restore the prior plugin payload and layout entry on rollback | Remove only that plugin and entries it added; preserve shared runtime while another consumer remains |
| Suite | Versioned GitHub release archive | Repository-owned files installed by `install.sh` into documented user paths | Explicit `--apply`, component selection, confirmation, then user-level service/theme activation | Transactional snapshot before mutation; exact manifest rollback; preserved `evangelion.json` | Manifest-driven rollback removes created files and restores replaced files; no directory-wide deletion |
| Arch package | AUR/Arch source package | Immutable suite payload under `/usr/share/evangelion-rice` and launchers under `/usr/bin` | Package installation does not modify `$HOME`; desktop user runs a separate activation command | Pacman owns system payload versions; user activation creates its own transaction for rollback | Pacman removes system payload; separate user deactivation restores that user's snapshot |

Theme and plugin catalog submissions are independently usable products, not
aliases for the suite installer. A plugin that imports suite-only files is not
eligible for the plugin tier until the runtime contract and plugin audit say it
is standalone.

## Ownership boundaries

There are three owners:

- The package manager owns files under `/usr/share/evangelion-rice` and
  `/usr/bin`. Package scripts must not treat a home directory as a package
  target.
- The suite transaction owns only the exact user paths recorded in its
  `manifest.tsv`. Existing targets are snapshotted before replacement and new
  targets are recorded for removal.
- The user owns preserved preferences, unrelated files, and every path not
  named by the selected tier. `~/.config/omarchy/evangelion.json` is created
  once and preserved on updates.

Complete-file replacements such as `shell.json` and the three Hyprland Lua
files require an explicit plan and confirmation. Catalog theme/plugin installs
must not replace those files. No tier may recursively copy over `$HOME`, infer a
desktop user from `sudo`, delete an unowned directory, or silently edit shell
startup files.

## Lifecycle contract

Every tier must provide a read-only preview or an exact file list before its
first user mutation. Activation and package installation are separate whenever
system and user ownership differ. An update may replace only payload owned by
that tier. Rollback must restore the immediately preceding state, including the
absence of newly created files. Removal must be idempotent and must retain:

- user preferences and state unless the user explicitly requests purge;
- dependencies shared by another installed tier or plugin;
- unrelated Omarchy themes, plugins, hooks, bar entries, and Hyprland config;
- rollback evidence needed to recover replaced user files.

The suite's current `install.sh --dry-run`, transactional `--apply`, and
`rollback.sh` behavior is the reference implementation. Theme extraction,
plugin packaging, and the Arch package must add tier-specific lifecycle tests.

## Versions, dependencies, and compatibility

The suite uses semantic versions and immutable Git tags. Release archives and
checksums identify the exact source. Theme and plugin packages version
independently once extracted; their metadata must also state the suite version
from which they were derived.

`dependencies.tsv` remains the suite's canonical command/package inventory.
Smaller tiers must publish a reduced dependency manifest and may not inherit
undeclared suite dependencies. Required dependencies block installation;
recommended dependencies affect the reference experience; optional dependencies
must degrade without broken or empty UI.

Supported means current Omarchy on Arch Linux with Hyprland and the Omarchy
shell APIs exercised by CI. Compatibility is capability-based where practical,
not tied to the T480. An Omarchy API/runtime range must be declared before a
standalone plugin is published. Breaking runtime, configuration-schema, or
activation changes require a major version; additive changes require a minor
version; compatible fixes require a patch version.

Support applies only to an unmodified released payload on a declared supported
environment. Reports from other hardware are welcome but optional; absence of
external hardware verification is not represented as a release failure.

## Artwork, licensing, and catalogs

Software and configuration are MIT-licensed. The wallpapers are separately
licensed under CC BY-NC 4.0 only to the extent described in
[`ASSETS_LICENSE.md`](ASSETS_LICENSE.md), and Evangelion names, designs, and
marks remain third-party property. Every artifact containing wallpapers must
include `ASSETS_LICENSE.md`, `theme/ARTWORK.md`, and the audited hashes. It must
be labeled unofficial and non-commercial and must not imply endorsement.

Channels that require commercial-use-compatible assets or a trademark grant
cannot accept the artwork-bearing theme or suite as currently constituted. A
software-only plugin may be distributed under MIT when it contains no wallpaper,
logo raster, or other separately licensed asset. Catalog acceptance is a
channel decision; this contract does not claim approval by Omarchy or any theme,
plugin, Arch, or AUR maintainer.

## Downstream gates

- Theme extraction must contain only the theme-tier payload and notices.
- The optional MAGI runtime must expose a versioned API with no theme dependency.
- Every plugin must be classified standalone, runtime-dependent, or suite-only.
- Release archives must be reproducible and carry checksums plus both licenses.
- The Arch package must keep pacman installation and per-user activation
  separate and test upgrade, rollback, deactivation, and removal.

Changes to these boundaries require updating both this document and
`distribution.json`, plus the distribution contract test.
