# MAGI context guide

MAGI context is a local, explainable input and recommendation layer introduced
in v1.3. It does not attempt to infer identity, intent, or activity from private
content. Collection is on demand, recommendations are advisory by default, and
automation requires two separate opt-ins.

## Inputs and privacy boundary

| Collector | Published facts | Explicitly excluded |
| --- | --- | --- |
| Power | AC/battery, aggregate charge, charging, battery count | Battery serials and vendor identifiers |
| Thermal | Highest usable temperature, pressure band, sensor count | Sensor labels and hardware identifiers |
| Displays | Internal/external counts and docked/mobile shape | Output names, EDID, make, model, and serial |
| Devices | Keyboard, pointer, audio input/output counts | Device names, addresses, and event contents |
| Connectivity | Connected, disconnected, or unknown | SSID, IP/MAC addresses, peers, DNS, and traffic |
| Media | Playing, paused, or stopped plus player counts | Track, artist, album, player identity, and artwork |
| Time | Local time band, weekend flag, UTC offset | Inferred location or network time queries |
| Operating profile | Explicit selected and active profile | Application, window, process, and document names |

Clipboard data, browser history, terminal contents, filesystem paths, process
titles, window titles, keystrokes, and microphone/camera payloads are never
collector inputs. Observations pass strict field, type, enum, and range
allowlists before publication. The controller imports no network client and
performs no network I/O.

Published state is mode `0600` at
`~/.local/state/evangelion-rice/context/state.json`. Read-only `status`,
`surface`, and `explain` commands do not collect or rewrite it. Only explicit
refreshes publish observations, and latest-request-wins locking prevents an
older process from overwriting a newer result.

## Derived states, reasons, and precedence

Policy v1 evaluates fresh normalized facts in this order:

1. Critical and high thermal or battery safety.
2. Elevated thermal or battery-conservation safety.
3. Explicit manual operating-profile selection.
4. Offline connectivity.
5. Docked or mobile environment.
6. Active media.
7. Nominal context.

Every result has a stable reason code, short summary, contributing allowlisted
facts, freshness, and any suppressed lower-priority alternatives. There is no
opaque intent label. Unknown, unavailable, stale, disabled, and no-fresh-input
states are stated directly.

Thermal and battery bands have separate entry/exit thresholds, and environment
mismatches require two consecutive observations. Contradictory observations
reset the candidate; recommendations have a five-minute cooldown. Stale facts
never participate in policy.

Inspect the current reasoning with:

```bash
magi-context status --json
magi-context explain
magi-context refresh --json
```

## Recommendations and automation

Recommendations and automatic actions are separate outputs. A recommendation
explains an environment/profile mismatch and requires confirmation. By default,
MAGI changes nothing.

Automation is limited to the existing `docked` and `mobile` operating profiles
and requires both opt-ins:

```bash
magi-context automation-rule environment_profile enable
magi-context automation enable
magi-context-automation preview
magi-context-automation apply --dry-run
```

Manual profile selection creates a visible hold and wins over automation.
Select `magi-operating-profile auto` to release that hold. The executor applies
a five-minute cooldown, deduplicates generations, captures the affected state,
rolls back a partial failure, reports the failed subsystem, and retains one
explicit undo snapshot:

```bash
magi-context-automation status --json
magi-context-automation undo
magi-context automation disable
```

The last command is the global kill switch; it does not hide recommendations.

## Surfaces and accessibility

The context inspector is available from `Super + Ctrl + Alt + G`, the MAGI menu, or
the bar glyph. Keyboard navigation and bounded scrolling remain available on
small displays. It renders a second presentation allowlist and never shows raw
signal values or numeric confidence.

OSDs, low-urgency notification borders, the start-page rail, and screensaver
HUD consume the fixed `magi-context surface` projection. They do not collect
hardware data themselves. Disable only those decorative cues with:

```bash
magi-context decorative disable
```

Stale, missing, unknown, unavailable, or disabled context resolves to the exact
v1.2 baseline. Full, Reduced, and Off motion settings remain authoritative;
context never overrides safety urgency, manual profiles, or motion/accessibility
preferences.

## Performance contract

There is no resident context daemon or background polling loop. Collectors run
only on an explicit refresh, use a bounded four-worker pool, and impose
two-second command deadlines. The v1.3 reference observation on the ThinkPad
T480 measured 12 live refreshes at 158.75 ms mean, 167.59 ms p95, and 168.35 ms
maximum against a 2000 ms bound. A three-second idle observation saw zero
context processes and zero context-state writes. The observer restored the
exact state, request counter, and controller lock it found.

Reproduce this optional, aggregate-only observation with:

```bash
./tests/context-observe.py test-results/context-observation.json
```

## Troubleshooting

```bash
magi-context status --json | jq '{generation,controller,derived_state,reasons}'
magi-context explain
magi-context refresh --json
magi-context-automation status --json
eva-capabilities | jq .
./tests/context-regression.py
```

An unavailable collector degrades independently. A still-fresh cached value is
retained after a transient failure, then becomes explicitly stale after
`max_age_seconds`. To return all context presentation to the v1.2 baseline,
run `magi-context disable`; re-enable and explicitly refresh when ready.

Unknown persisted schemas are ignored by read-only commands. The first explicit
refresh publishes a clean schema-v1 generation without using legacy state as
policy input.
