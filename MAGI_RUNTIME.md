# Optional MAGI runtime contract

This document is the normative compatibility contract for reusable Evangelion
plugins. Its machine-readable companion is
[`magi-runtime-contract.json`](magi-runtime-contract.json).

## Decision

There is **no separately installed MAGI runtime package for contract version
1**. Reusable plugins ship a self-contained core and may add MAGI behavior only
through explicit, capability-detected adapters. Small QML fallbacks belong in
each plugin repository; they are not imported from a sibling plugin directory.

This is an intentional avoidance, not an unfinished package. It prevents a
visualizer or media widget from silently installing theme assets, commands,
context collection, automation, or the full suite. If three or more extracted
plugins later duplicate a stable implementation, this decision may be revisited
with a new contract version and an independently removable package.

## Version and discovery

Contract versions use semantic versioning. A consumer declares a range such as
`>=1.0.0 <2.0.0`; incompatible major versions are never guessed compatible.

Optional command capabilities are discovered by executable name and then
verified with `<command> capabilities --json`. A successful probe exits zero
and returns this envelope:

```json
{
  "contract": "magi.optional-runtime",
  "version": "1.0.0",
  "capabilities": {
    "motion": { "version": "1.0.0", "commands": ["status"] }
  }
}
```

Absence, timeout, nonzero exit, malformed JSON, a different contract name, or
an unsupported version means **capability unavailable**. It is never a fatal
plugin error. Probes must be local, read-only, bounded to 250 ms, and may not
trigger installation or network access.

The current suite commands predate this discovery command and therefore are
not claimed as implementations of this public contract. Extraction work may
add compliant adapters without changing the private suite APIs.

## Version 1 surface

The public surface is deliberately narrow.

### Commands

| Capability | Probe/operation | Success payload | Failure behavior |
|---|---|---|---|
| Runtime discovery | `magi-runtime capabilities --json` | Discovery envelope above | Treat all optional capabilities as absent |
| Motion read | `magi-runtime motion status --json` | `{"schema_version":1,"mode":"full|reduced|off"}` | Use the plugin-local default `reduced` |

There are no public mutation commands in version 1. Plugins must not change
motion, context, affinity, profiles, or theme state merely because they load.

### State schemas

Plugins do not read suite-private files. If a future runtime publishes state,
version 1 reserves `$XDG_STATE_HOME/magi-runtime/v1/<capability>.json`; every
document must contain `schema_version`, be atomically replaced, and be treated
as an optional cache. Command output remains authoritative. Unknown fields are
ignored, while an unknown `schema_version` makes that capability unavailable.

### QML interface

No cross-repository QML import is public in version 1. A plugin-local adapter
may expose these properties to its own components:

```qml
QtObject {
  readonly property bool available
  readonly property string contractVersion
  readonly property string motionMode // full, reduced, or off
}
```

The adapter defaults to `available: false`, an empty version, and
`motionMode: "reduced"`. It may enhance behavior after a valid probe, but the
plugin's primary content and controls must remain useful before and after that
probe. Theme colors come from the Omarchy shell API or plugin-owned defaults,
never from a MAGI theme file.

## Required versus optional dependencies

Each extracted plugin publishes three separate lists:

- **Required:** Omarchy shell/API versions and commands without which the
  plugin has no useful function. Installation may stop when these are absent.
- **Recommended:** experience-enhancing dependencies such as `cava`; their
  absence must produce an intentional hidden or explanatory state.
- **Optional MAGI capabilities:** motion and any future context integration.
  These never cause installation of another component and never block use.

For the first candidates, `evangelion.cava` requires the Omarchy bar API and
recommends `cava`; `evangelion.media` requires a compatible native
`omarchy.media` service. Neither requires MAGI runtime, theme, wallpaper,
context, or suite commands.

## Failure and degradation semantics

Capability state is one of `absent`, `compatible`, `stale`, or `incompatible`.
Only `compatible` may enable an enhancement. A cached response older than 30
seconds is stale. A runtime that disappears or becomes invalid returns the
adapter to its local fallback without removing the widget, breaking input, or
showing a persistent error. Diagnostics may log one rate-limited message but
must not notify the user repeatedly.

Motion fallback is deterministic: use reduced transitions, no continuous
decorative animation, and instant safety-critical feedback. With motion
available, `full`, `reduced`, and `off` are honored. Cava still hides cleanly
when its recommended executable is absent. Media still hides when no player is
active and must show a non-crashing unsupported-service state when the native
media API is unavailable.

## Compatibility matrix and release gate

Every independently published plugin must be tested in isolation against:

| Runtime state | Expected result |
|---|---|
| Absent | Useful plugin-local fallback; no sibling imports or MAGI commands |
| Present and compatible | Advertised enhancements activate |
| Stale state/cache | Ignore cache and use fallback until a valid probe succeeds |
| Incompatible major/schema | Use fallback; one bounded diagnostic; no partial integration |
| Malformed, failing, or timed out | Same as absent; startup and controls remain responsive |

Tests must run from an isolated plugin root with an empty fake home and command
path. A plugin cannot be described as standalone until all applicable rows pass
and its manifest declares required, recommended, and optional dependencies.

## Evolution

Additive capabilities and fields require a minor contract version. Compatible
clarifications and fixes require a patch. Removing or changing a command,
meaning, default, schema, or QML property requires a new major version. Plugins
must continue to work without the runtime across every version.
