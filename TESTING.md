# Clean-user test procedure

The portable installer has two complementary test layers:

```bash
./tests/installer.sh
./tests/clean-user.sh
```

`installer.sh` exercises individual transaction mechanics in a temporary home.
`clean-user.sh` simulates a fresh, logged-in Omarchy user with isolated config,
data, state, and command-event paths. It never writes to the invoking user's
home or communicates with the live Hyprland session.

The clean-user harness covers minimal and full dependency profiles, seeded user
configuration, a full install, session activation, explicit theme selection,
post-activation validation, a repeat install, legacy namespace upgrade, forced
failure recovery, rollback, and uninstall-equivalent cleanup.

Its machine-readable report defaults to:

```text
test-results/clean-user.json
```

Pass another output path as the first argument when running in CI or a disposable
VM. GitHub Actions uploads this JSON report as the `clean-user-results` artifact.
Real hardware and display-matrix testing remains separate from this isolated
harness and is tracked by the responsive-layout and external-beta roadmap work.
