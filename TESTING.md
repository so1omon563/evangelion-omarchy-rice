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
./tests/lifecycle-motion.py test-results/lifecycle-motion.json
./tests/affinity-motion.py test-results/affinity-motion.json
./tests/mode-transition.py test-results/mode-transition.json
./tests/bar-motion.py test-results/bar-motion.json
./tests/motion-observe.py test-results/motion-observation.json
```

The local context foundation has isolated schema, preference, atomic-write, and
concurrency coverage:

```bash
./tests/context.py
./tests/context-collectors.py
./tests/context-policy.py
```

It uses a temporary home and asserts that read-only status creates no state,
invalid configuration is not overwritten, private/network primitives are not
imported, and a delayed older refresh cannot overwrite the latest request.
`context-collectors.py` uses fake sysfs hardware and normalized observation
fixtures to cover multi-battery power, thermal thresholds, missing commands,
fresh-cache retention, stale transitions, strict privacy-schema rejection, and
the exact normalized fact set without querying the live desktop.

`context-policy.py` uses table-driven conflicts and exact boundary sequences to
verify stable precedence, thermal and battery hysteresis, two-sample debounce,
recommendation cooldown, contradictory-input convergence, stale-input
exclusion, contributing facts, and the permanent separation of recommendations
from automatic actions.

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
`lifecycle-motion.py` enforces lock-first phase arbitration, immediate
screensaver dismissal, boot retirement, authoritative timers, and complete
Full/Reduced/Off paths without waiting for real idle or powering off a display.
`affinity-motion.py` verifies wallpaper detection, neutral fallback, serialized
rapid-settle behavior, atomic profile state, manual authority, Auto feedback,
and Off-mode instant presentation without changing any wallpaper asset.
`mode-transition.py` verifies all seven coordinated mode families, unfocused
non-obscuring feedback, Full/Reduced/Off paths, exact-client restoration,
duplicate suppression, partial-launch rollback, manual Angel exit, dock rescue,
and wallpaper-aware presentation placement without launching applications.
`bar-motion.py` checks shared fixed-geometry cues across every required widget,
immediate safety-critical paths, still nominal state, no label/layout animation,
independent Cava gating, affinity-without-width, and responsive bounds.

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
