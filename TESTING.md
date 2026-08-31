# Clean-user test procedure

The portable installer has two complementary test layers:

```bash
./tests/installer.sh
./tests/clean-user.sh
```

Motion has two additional evidence layers:

```bash
./tests/motion-regression.py test-results/motion-regression.json
./tests/lock-motion.py test-results/lock-motion.json
./tests/motion-observe.py test-results/motion-observation.json
```

`motion-regression.py` is portable CI coverage for rapid Full/Reduced/Off
changes, persistence, interruption/coalescing contracts, critical-state
immediacy, hidden-surface activity guards, duplicate polling signatures, and
the seven-profile responsive matrix. `motion-observe.py` is an optional live
reference-hardware sampler: it records privacy-safe aggregate CPU, RSS, and
thread observations for idle and transition activity, then restores the exact
motion mode it found. It requires a running Omarchy shell and is not run in CI.
`lock-motion.py` statically enforces immediate opaque lock coverage, masked
credentials, mode-aware post-success feedback, recovery hooks, and abort-first
stationary power confirmations without invoking any real session action.

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
VM. GitHub Actions uploads the clean-user, responsive-layout, and motion-regression
JSON reports together as the `validation-results` artifact.
Physical hardware coverage beyond the reference T480 is not asserted by this
harness. Responsive layouts have a separate automated matrix, and optional
community compatibility reports can extend observed physical-hardware coverage.
