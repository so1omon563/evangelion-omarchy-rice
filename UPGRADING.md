# Upgrade, rollback, and removal

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
