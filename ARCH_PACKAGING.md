# Arch package and user activation

The Arch package owns immutable suite files under `/usr/share/evangelion-rice`
and the `/usr/bin/evangelion-rice` dispatcher. Package installation, upgrade,
and removal never inspect or mutate a home directory, start services, reload
Hyprland, or contact an active desktop session.

## Package designs

- `packaging/arch/PKGBUILD.release.in` is the reproducible release template.
  `scripts/build-arch-package` fills its version and SHA-256 from a verified,
  exact-tag suite archive.
- `packaging/arch/PKGBUILD-git` is the optional VCS design. It declares
  `provides`/`conflicts` against the release package and derives `pkgver` from
  Git. It is for testers, not the stable distribution path.

Build locally after producing an approved tagged archive:

```bash
./scripts/build-release build --tag v1.4.1
./scripts/build-arch-package build/release/evangelion-omarchy-rice-1.4.1.tar.gz
cd build/arch
makepkg --printsrcinfo > .SRCINFO
makepkg --cleanbuild
namcap PKGBUILD evangelion-omarchy-rice-1.4.1-1-any.pkg.tar.zst
```

The generated PKGBUILD expects the archive at the matching GitHub Release URL.
The checksum-pinned stable `PKGBUILD` is attached to the
[latest GitHub release](https://github.com/so1omon563/evangelion-omarchy-rice/releases/latest).
CI validates packaging in an isolated package root without installing into the
host. AUR publication is deferred: there is no maintained AUR repository yet.
The scripts never publish externally on their own.

## Explicit per-user lifecycle

After pacman installs the package, run these as the desktop user—never with
`sudo`:

```bash
evangelion-rice preflight
evangelion-rice plan --preset default
evangelion-rice setup --preset default
evangelion-rice status
evangelion-rice upgrade --preset default
evangelion-rice rollback /path/to/snapshot
evangelion-rice deactivate
```

`setup`/`upgrade` use the suite's manifest-backed transaction. `deactivate`
restores the last snapshot and clears its activation pointer. `remove` is an
alias for user deactivation; it deliberately does not call pacman. After
deactivation, remove the immutable system payload separately:

```bash
sudo pacman -Rns evangelion-omarchy-rice
```

Pacman removal cannot and must not guess whether per-user files are active.
The package has no install script, post-install hook, privileged desktop
mutation, or automatic activation.
