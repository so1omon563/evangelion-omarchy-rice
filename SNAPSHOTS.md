# Named configuration snapshots

`magi-snapshot` stores private, named copies of suite-owned configuration
independently of installer rollback. The ownership boundary is the exact,
versioned `omarchy/snapshot-manifest.json`; there are no globs and callers
cannot supply paths. Layouts, profiles, affinity authority, and settings can be
captured or restored together or selectively.

```bash
magi-snapshot create before-dock --note "Before dock layout tuning"
magi-snapshot list
magi-snapshot show before-dock
magi-snapshot diff before-dock --components layouts,profiles
```

`diff` is read-only and returns a `plan_id`. Restore requires the same
component selection and exact plan identifier:

```bash
magi-snapshot restore before-dock --components layouts,profiles --confirm PLAN_ID
magi-snapshot rollback TRANSACTION_ID
```

Before mutation, restore validates every snapshot payload checksum and size,
then records the exact current state in a private transaction. Failure during
application invokes rollback. Missing or corrupt manifests, payloads, or
rollback backups stop before unsafe mutation. Symlinks and non-regular files
are rejected to prevent indirect capture.

Snapshot names are portable slugs; notes are limited to 240 characters.
Secret-like note text and JSON keys (passwords, credentials, tokens, cookies,
and private/API keys) are rejected. Snapshots never include arbitrary files,
plugin source, accounts, browser state, weather caches, device identifiers, or
files outside the ownership manifest. Directories are mode `0700`; manifests,
payloads, and transaction backups are mode `0600`.

The default retention policy keeps ten named snapshots. Creating the eleventh
prunes the oldest snapshot only after the new snapshot is complete. Restore
transactions are not counted as named snapshots and are never pruned by this
policy.
