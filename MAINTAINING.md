# Maintainer distribution workflow

This checklist keeps the standalone theme, complete suite, release archive,
Arch package, gallery metadata, documentation, and privacy-reviewed media in
sync without merging their ownership boundaries.

## Source of truth

- The complete suite repository is authoritative for code, configuration,
  distribution policy, release notes, and the canonical `theme/` source.
- `scripts/export-theme` derives the standalone declarative theme payload.
- The dedicated theme repository contains only that export plus its public
  README and licensing files.
- `distribution.json` and `DISTRIBUTION.md` define supported channels.
- `packaging/release/allowlist.txt` defines the complete release archive.
- `packaging/arch/PKGBUILD` and `packaging/arch/evangelion-rice` define Arch
  system ownership and explicit user activation.

MAGI plugins remain internal to the complete suite in v1.4. Do not publish a
plugin or runtime artifact from this workflow.

## Synchronize a release candidate

1. Start from a clean suite worktree and select the exact semantic version.
2. Update `RELEASE_NOTES.md`, compatibility claims, migration instructions,
   archive examples, and package version/checksum fields.
3. Run `scripts/export-theme` into a temporary directory and compare it with
   the dedicated theme repository. Commit only intentional declarative-theme,
   README, license, provenance, and wallpaper changes there.
4. Validate the dedicated theme install/update/background/removal lifecycle.
5. Rebuild gallery metadata only if the public preview or theme repository
   reference changed. Keep the entry alphabetized and the suite link visible in
   the theme README.
6. Confirm every public image is listed by the privacy-reviewed media contract;
   strip metadata and reject names, paths, browser content, notifications, live
   telemetry, or other private state. Synthetic/demo state must be labeled.
7. Run the complete local gate and retain machine-readable results:

   ```bash
   EVANGELION_SOURCE_ONLY=1 EVANGELION_RELEASE_131_NESTED=1 ./validate.sh
   ./tests/cross-channel.py
   ```

8. Commit, push, and wait for the exact candidate CI run to pass. A queued or
   asynchronous run is not release evidence.

## Build and publish the complete suite

After CI is green, create and verify the signed/annotated exact tag, then build
twice and compare checksums:

```bash
git tag --verify v1.4.0
./scripts/build-release build --tag v1.4.0 --output build/one
./scripts/build-release build --tag v1.4.0 --output build/two
cmp build/one/*.tar.gz build/two/*.tar.gz
./scripts/build-release verify build/one/evangelion-omarchy-rice-1.4.0.tar.gz
```

Inspect the archive manifest and provenance, publish the archive and checksum
to the matching GitHub release, and test the public download in an isolated
home. Package installation, upgrade, rollback, and removal must use the exact
published bits—not a nearby checkout.

For the Arch channel, update `pkgver`, source URL, and checksum from that exact
release. Build in a clean Arch environment, inspect `pacman -Qlp`, and run the
explicit per-user activation lifecycle. Package hooks must never mutate an
active desktop user's home or session.

## Theme gallery review

The official gallery lists the independently installable theme, not the full
suite. Follow `packaging/gallery/SUBMISSION.md`: validate the public theme URL,
use the reviewed 1200×675 WebP, preserve alphabetical placement, show the exact
site diff, and obtain owner approval before opening or updating the external PR.

The complete suite stays on GitHub Releases (and optionally Arch/AUR) because
it owns executable commands, shell plugins, Hyprland configuration, services,
and transactional user changes that a declarative Omarchy theme cannot safely
or accurately represent.

## Final release checklist

- [ ] Version, supported ranges, release notes, and migration docs agree.
- [ ] Standalone theme export and dedicated repository are synchronized.
- [ ] Theme README links clearly to the complete suite.
- [ ] Gallery image and repository commit are privacy/licensing reviewed.
- [ ] MAGI plugins are described only as suite-internal components.
- [ ] Optional runtime remains a contract only; no runtime artifact is implied.
- [ ] Release allowlist contains every required public guide and excludes local evidence.
- [ ] Reproducible archive, checksum, manifest, and provenance verify.
- [ ] Arch package owns only system payload; user activation remains explicit.
- [ ] Cross-channel, upgrade, rollback, removal, browser, motion, privacy, and responsive tests pass.
- [ ] Exact pushed commit/tag CI passes and machine-readable artifacts are retained.
- [ ] Public release notes link installation, maintenance, rollback, licensing, and support guidance.

