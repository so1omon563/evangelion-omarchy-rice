# Complete-suite release artifacts

The complete Evangelion Rice suite is distributed as a reproducible tarball.
It is separate from the independently installable theme and does not publish
the suite's internal MAGI plugins as standalone products.

## Build from an exact tag

The working tree is never used as artifact input. Commit the intended release,
create and verify its semantic-version tag, then build:

```bash
git tag --verify v1.4.0
./scripts/build-release build --tag v1.4.0
```

The builder rejects branches, raw commits, missing tags, and non-semantic tag
names. It reads blobs directly from Git, uses the tagged commit timestamp,
sorts every entry, and normalizes archive ownership. Repeating the command for
the same tag produces identical bytes.

Output is written to `build/release/` and is intentionally ignored by Git:

- `evangelion-omarchy-rice-1.4.0.tar.gz`
- `evangelion-omarchy-rice-1.4.0.tar.gz.sha256`

The artifact includes `RELEASE-PROVENANCE.json` with the exact tag and commit,
plus `RELEASE-MANIFEST.sha256` covering every payload file. The external
checksum covers the compressed archive.

## Verify and use offline

Download both files into the same directory, then run:

```bash
sha256sum --check evangelion-omarchy-rice-1.4.0.tar.gz.sha256
tar -xzf evangelion-omarchy-rice-1.4.0.tar.gz
cd evangelion-omarchy-rice-1.4.0
./scripts/build-release verify ../evangelion-omarchy-rice-1.4.0.tar.gz
./preflight.py --source-only
./install.sh --dry-run --preset default
./install.sh --apply --preset default
```

`--source-only` performs offline source validation; normal preflight checks the
live Omarchy environment. Installation, repeated installation/upgrade, and
rollback use the same transactional commands as a Git checkout. The install
prints its rollback snapshot; restore or remove that transaction with:

```bash
./rollback.sh /path/printed/by/install
```

Do not delete the snapshot before rollback. A broad recursive uninstall is
intentionally not provided because it could remove user-owned files.

## Contents and publication boundary

[`packaging/release/allowlist.txt`](packaging/release/allowlist.txt) is the only
source allowlist. Git-ignored captures, caches, private validation evidence,
generated results and tests, repository metadata, gallery packaging, historical
release evidence, and promotional media are excluded. Runtime assets,
licensing, documentation, lifecycle scripts, and artifact-integrity validation
are retained. The installer detects a release root and validates its internal
manifest instead of running repository-development checks for excluded files.

CI builds the archive twice, compares it byte-for-byte, verifies both checksum
layers, and exercises preflight, dry-run, install, upgrade, rollback, and
removal in an isolated home. CI retains the result only as validation evidence;
it does not create a GitHub Release or publish an artifact until owner approval.
