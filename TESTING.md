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
./tests/context-surfaces.py
./tests/context-automation.py
./tests/operating-profile-transaction.py
./tests/ambient.py
./tests/context-regression.py
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

`context-panel.py` enforces the inspector's compact-JSON transport, explicit
refresh-only collection, fixed fact/signal/recommendation allowlists, bounded
scrollable geometry, plain unknown/unavailable/disabled states, keyboard focus
and activation, global motion integration, menu entry, and documented hotkey.

`context-surfaces.py` verifies that the OSD, notifications, start page, and
screensaver use the shared presentation-safe projection, contain no duplicated
hardware detection, preserve fixed geometry, and fall back to a hidden or
neutral v1.2 baseline when context is missing or decorative cues are disabled.

`context-automation.py` uses an isolated home and fake profile executor to
prove double opt-in, the dock/mobile action allowlist, manual and temporary
holds, dry-run, generation deduplication, cooldown, failed-subsystem reporting,
and undo without touching the live desktop. It also asserts that AC/battery,
presentation, thermal, and focus-shaped inputs cannot smuggle unsupported
actions into the executor.

`operating-profile-transaction.py` supplies fake display, power, and audio
subsystems. It forces a mid-transaction audio failure and verifies exact bar
and active-profile rollback, then covers successful apply, explicit undo, and
the manual-selection hold.

`ambient.py` fixes the clock, supplies explicit mission/focus state, and checks
location-free bands, offline solar calculation and daily cache reuse, quiet and
disable fallback contracts, prohibited geolocation/network primitives, and the
absence of an ambient polling loop.

`context-regression.py` adds incompatible-schema fallback and explicit
migration, independent-process restart continuity, killed-refresh recovery,
rapid latest-request convergence, unavailable capability handling, and private
sentinel checks across stdout, stderr, persisted state, requests, surfaces,
explanations, demos, and diagnostics. It also pins the existing precedence,
stale-input, manual-hold, rollback, clean-user, and lock-safety coverage into one
acceptance map.

Optional reference-hardware context timing is separate from CI because it reads
live local capabilities:

```bash
./tests/context-observe.py test-results/context-observation.json
```

It records aggregate refresh latency/child CPU and a three-second idle polling
observation. It snapshots the live context state, request counter, and lock file
before the run and atomically restores their exact bytes and modes in a
`finally` block.
The report contains no paths, signal values, process IDs, or machine identifiers.

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
`start-page-context.py` verifies the local desktop endpoint's affinity identity,
freshness states, MAGI workspace labels, unavailable fallbacks, two-second
bounded refresh contract, and privacy field exclusions.

`release-v1.3.1.py` executes both mixed browser-bundle directions, requires
versioned/no-store assets, and performs an exact v1.3.0 install followed by a
v1.3.1 upgrade, upgrade rollback, repeated upgrade, and complete removal in an
isolated home.

`release-v1.4.py` pins the exact RC tag and green candidate commit, final
distribution decisions, documentation selection/maintenance contracts, and all
privacy-reviewed public media hashes. `cross-channel.py` exercises standalone
theme conflict refusal, suite install, forced partial failure, exact rollback,
internal-plugin policy, and browser/motion/privacy/responsive compatibility;
CI retains its machine-readable JSON evidence.

`magi-extension-contract.py` runs the v1 internal suite adapter against an
isolated fake command path. It covers capability negotiation, compatible data,
partial failure, missing providers, malformed output, 250 ms provider timeouts,
complete static fallback, settings minimization, and privacy-safe projection.

`recovery.py` starts with deliberately broken/private shell and Hyprland
fixtures, enters the stock-only recovery path, checks the minimized evidence,
proves repeated activation is idempotent, restores exact bytes and permissions,
and verifies that targets absent before recovery return to absence afterward.

`migration.py` proves that preview is byte-for-byte read-only, unresolved and
unknown conflict choices block before mutation, per-file keep/replace choices
are journaled, successful migration rolls back exactly, and a forced failure
after the first write blocks new work until validated recovery restores every
original file and permission.

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
`bar-icons.py` verifies the upstream adapter inventory, native behavior
delegation, shared normal/hover/active/attention/error palette, fixed geometry,
portable source lookup, vendor-icon policy, and documented stock fallback.

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
