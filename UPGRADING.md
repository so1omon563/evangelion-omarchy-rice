# Upgrade, rollback, and removal

## Upgrade from v1.3.1 to v1.4

v1.4 preserves the v1.3.1 desktop behavior while adding distribution metadata,
cross-channel safeguards, and public release packaging. Do not install the
standalone theme over an existing suite—or the suite over a Git-installed
standalone theme—because both own the `evangelion` theme path.

Download the new archive and matching checksum from the GitHub release, verify
them, and preview the same preset or components used previously:

```bash
sha256sum --check evangelion-omarchy-rice-1.4.1.tar.gz.sha256
tar -xzf evangelion-omarchy-rice-1.4.1.tar.gz
cd evangelion-omarchy-rice-1.4.1
./scripts/build-release verify-root .
./preflight.py
./install.sh --dry-run --preset default
./install.sh --apply --preset default
snapshot=$(cat ~/.local/state/evangelion-rice/last-install-backup)
./validate.sh
```

Replace `default` with the prior selection. Personal `evangelion.json`, motion,
context, affinity, and profile choices remain preserved. To return to the exact
pre-v1.4 filesystem state:

```bash
./rollback.sh "$snapshot"
omarchy restart shell
hyprctl reload
hyprctl configerrors
```

Git-checkout users may use `git pull --ff-only` instead of downloading an
archive, after confirming `git status --short` is clean. Arch users must first
deactivate a source/archive activation, install the package, and then explicitly
run `evangelion-rice setup`; see `ARCH_PACKAGING.md` and `CROSS_CHANNEL.md`.

## Upgrade from v1.3.0 to v1.3.1

v1.3.1 changes shell plugins, affinity commands, and start-page assets. Update
the checkout and preview the same preset or components used for v1.3.0:

```bash
git status --short
git pull --ff-only
./preflight.py
./install.sh --dry-run --preset default
./install.sh --apply --preset default
snapshot=$(cat ~/.local/state/evangelion-rice/last-install-backup)
./validate.sh
```

Replace `default` with the previously installed preset or explicit component
selection. Personal `evangelion.json`, motion, context automation, and affinity
mode choices remain preserved. A normal browser refresh fetches versioned,
no-store start-page assets; clearing Zen or Chromium profile data is not
required.

Verify the live semantic projection and restart-free palette path:

```bash
curl --fail http://127.0.0.1:8765/api/desktop | jq .
magi-bar-refresh status | jq .
```

To restore the exact pre-v1.3.1 files from this transaction:

```bash
./rollback.sh "$snapshot"
omarchy restart shell
systemctl --user restart magi-start-page.service
```

The restart after rollback is necessary because an older on-disk start-page or
shell implementation may have been restored. It is not part of normal affinity
switching or the v1.3.1 upgrade path.

## Upgrade from v1.2 to v1.3

Preserve local repository edits, update, and preview the same preset or explicit
component selection used for v1.2:

```bash
git status --short
git pull --ff-only
./preflight.py
./install.sh --dry-run --preset default
./install.sh --apply --preset default
omarchy theme set evangelion
./validate.sh
```

Record the exact snapshot printed by `install.sh` before doing anything else:

```bash
snapshot=$(cat ~/.local/state/evangelion-rice/last-install-backup)
test -f "$snapshot/manifest.tsv"
```

The transaction preserves `~/.config/omarchy/evangelion.json` and adds missing
v1.3 context/ambient defaults in memory without silently opting into automation.
The context controller ignores unknown persisted schemas until an explicit
refresh publishes clean schema v1. Verify the new layer without enabling
automation:

```bash
magi-context status --json
magi-context refresh --json
magi-context explain
magi-context-automation preview
```

To return to the exact pre-v1.3 filesystem state, use the recorded snapshot:

```bash
./rollback.sh "$snapshot"
omarchy restart shell
hyprctl reload
hyprctl configerrors
```

Rollback restores every replaced file and removes every file created by that
single v1.3 transaction. It does not reverse older transactions or delete
preserved personal configuration. If the shell component was not part of your
v1.3 selection, omit the shell restart; if Hyprland was not selected, the reload
is harmless but optional.

## Upgrade from v1.1

Keep any local repository edits, update, and preview the same preset used for
v1.1:

```bash
git status --short
git pull --ff-only
./preflight.py
./install.sh --dry-run --preset default
./install.sh --apply --preset default
omarchy theme set evangelion
./validate.sh
```

Replace `default` with `minimal`, `full`, or your prior explicit component
selection. The transaction preserves `~/.config/omarchy/evangelion.json` and
the selected `motion.mode`; it adds the coordinated motion token profile and
dynamic shell services. Verify the resolved setting with `magi-motion show`.

To return to the exact pre-upgrade state, run `./rollback.sh` with the snapshot
printed by the apply transaction, then run `omarchy restart shell` and
`hyprctl reload`. Rolling back restores replaced files and removes files newly
created by that transaction; it does not erase older snapshots or personal
configuration that the installer did not own.

## Upgrade from v1.0-era installs

Update without overwriting local uncommitted work, then preview:

```bash
git status --short
git pull --ff-only
./preflight.py
./install.sh --dry-run --preset default
```

Apply the preset previously used, or explicit components. The shell component
moves old `so1omon.*` plugin directories into the rollback snapshot and installs
public `evangelion.*` IDs. It updates layouts, manifests, QML modules, and
services together while preserving `~/.config/omarchy/evangelion.json`.

```bash
./install.sh --apply --preset default
omarchy theme set evangelion
./validate.sh
```

Do not manually rename plugin directories.

## Recover a transaction

Failed transactions roll back automatically. To reverse a successful latest
transaction:

```bash
cat ~/.local/state/evangelion-rice/last-install-backup
./rollback.sh
```

For an older transaction, inspect its manifest first:

```bash
snapshot=~/.local/state/evangelion-rice/install-backups/<snapshot-name>
less "$snapshot/manifest.tsv"
./rollback.sh "$snapshot"
```

## Safe uninstall-equivalent recovery

There is intentionally no broad recursive uninstall command. A fresh install
is removed safely by rolling back its installation snapshot. With multiple
apply transactions, each snapshot represents only its delta:

1. Save personal edits made after installation.
2. List snapshots newest first with
   `ls -1dt ~/.local/state/evangelion-rice/install-backups/*`.
3. Inspect each `manifest.tsv`.
4. Roll back applicable snapshots newest to oldest until the initial install
   is reversed.
5. Verify repository source with `EVANGELION_SOURCE_ONLY=1 ./validate.sh`.
6. Reapply the prior non-Evangelion theme and restart the shell if needed.

Do not recursively delete `~/.config/omarchy`, `~/.config/hypr`, or the backup
tree. They can contain unrelated data and the only copies of replaced files.
