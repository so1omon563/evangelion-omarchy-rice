# Performance budgets

SO1-409 turns performance expectations into versioned gates. The reference is
the ThinkPad T480 on the supported Omarchy 4.0 stack; budgets are ceilings, not
claims that every machine will produce identical measurements.

The first instrumented reference run is recorded in
`evidence/performance-v1.5.json`. The prior state is explicitly marked
unmeasured rather than reconstructed. CPU and RSS ceilings include modest
headroom over that observed baseline so CI detects regressions instead of
encoding an already-failing aspiration.

| Metric | Budget |
|---|---:|
| Shell configuration ready | 3000 ms |
| Idle shell CPU | 12% of one core |
| Idle shell RSS | 650 MiB |
| Shell IPC command p95 | 350 ms |
| Default background poll interval | at least 5000 ms |
| Concurrent probes per component | 1 |

Run `magi-performance-budget static` for the deterministic inventory gate and
`magi-performance-budget measure` for a payload-blind live report. Missing
`/proc`, logs, or shell IPC produces `partial`, not invented zeroes. A measured
limit violation produces `failed`. Reports contain only aggregate numbers and
metric names; never PIDs, commands, payloads, paths, hostnames, or identity.

The performance overlay displays the latest explicit budget result but does
not run measurements itself. It remains disabled by default. It performs one probe per cycle
when enabled and has no hidden animation when closed.

Short intervals are permitted only for visible interaction or safety-critical
work. Battery uses a 30-second safety check; thermal monitoring is event-driven;
lock timers exist only during authentication; notification timers exist only
during visible card lifecycle. Every exception is named and justified in the
budget configuration. New exceptions require code review and documentation.

CI validates the declared polling inventory, overlap ceiling, hidden-animation
flag, passing and failing measurement fixtures, graceful unavailable behavior,
privacy boundary, cache age ceilings, and integration with the developer
overlay. Update the budget, inventory, evidence, tests, and this methodology in
one change—never relax a limit solely to silence a regression.

Live startup is derived from Quickshell's launch-to-configuration-loaded log
timestamps. Idle CPU and aggregate RSS come from a half-second `/proc` sample.
Command p95 uses the slowest of five shell pings as a deliberately conservative
small-sample proxy. Cache freshness uses file modification age only; cache
paths and contents are never included in the report.
An inactive or paused mission has no freshness requirement and is reported
unavailable; a running mission is checked against its declared boundary.
