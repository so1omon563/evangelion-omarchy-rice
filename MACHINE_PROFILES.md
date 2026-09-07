# Portable machine profiles

Portable machine profiles transfer operating and display-layout preferences
without transferring machine identity or private state.

```bash
magi-machine-profile export ~/evangelion-machine.json
magi-machine-profile import ~/evangelion-machine.json
magi-machine-profile import ~/evangelion-machine.json --confirm PLAN_ID
magi-machine-profile rollback TRANSACTION_ID
```

Exported bundles use the versioned `evangelion-machine-profile` schema. The
export report accounts for removed connector/device identifiers, display
descriptions, hardware fingerprints, window addresses, paths, accounts,
weather location, and private runtime state. Files are written atomically with
mode `0600`.

Display outputs become semantic roles such as `internal` and `external-1`.
Import maps those roles to the destination machine. A topology requiring roles
that do not exist is reported and skipped without blocking compatible profiles.
Unavailable power-profile or audio capabilities are remapped to `keep` and
listed explicitly in the preview.

The first import command is a read-only dry run. It reports name conflicts,
capability substitutions, skipped layouts, and an exact plan ID. Apply rechecks
the bundle digest and destination capabilities, backs up every target, writes
atomically, verifies the result, and automatically restores the prior files on
failure. The printed transaction ID supports a later explicit rollback.

Machine-profile files are intended for deliberate person-to-person transfer.
Review the redaction report and preview before sharing or applying one.
