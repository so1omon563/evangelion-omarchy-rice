# Internal MAGI extension contract

`magi.extension-state` version 1 is the stable, read-only state boundary for
widgets shipped inside the complete Evangelion rice. It is **not a standalone
runtime**, plugin dependency, or public promise that extracted plugins may
import suite internals. The separate optional-runtime decision in
[`MAGI_RUNTIME.md`](MAGI_RUNTIME.md) remains unchanged.

## Consumer interface

Future suite widgets call `magi-extension-state capabilities --json` once and
then `magi-extension-state snapshot --json` when they need state. They do not
read another feature's files, invoke its private command, or import a sibling's
service solely to learn affinity, motion, operating profile, settings, health,
or presentation context.

Discovery is local and read-only and should be bounded by consumers to 250 ms.
A snapshot should be bounded to 1.5 seconds. The adapter bounds every underlying
probe to 250 ms and always returns a complete static fallback. Loading a widget
must never change settings or cause network access.

Every snapshot contains the contract/version, generation time, a status and
schema version for each capability, and a state object for every capability.
Capability status is `compatible`, `unavailable`, `timed-out`, or `invalid`.
Only `compatible` data may enhance a widget. All other states are intentional,
non-crashing fallbacks; they must not produce repeated notifications.

## Capability negotiation and schemas

The machine-readable authority is
[`magi-extension-contract.json`](magi-extension-contract.json). Consumers must
reject an unknown contract name or major version, ignore unknown additive
fields, and independently inspect each capability's status and schema version.
One failed probe never invalidates the remaining snapshot.

The presentation capability contains only the existing `magi-context surface`
projection. Settings are reduced to visual behavior switches. Health is the
existing aggregate health model. The adapter does not expose usernames, home
paths, hostnames, addresses, SSIDs, process IDs, or window titles.

## Failure, fallback, and migration policy

Missing commands yield `unavailable`; a deadline yields `timed-out`; malformed
or wrongly shaped output yields `invalid`. In every case the contract-defined
static fallback is returned in `state`. Results are never silently recovered
from suite-private cache files.

Additive fields or capabilities require a minor version. Clarifications require
a patch. Removing a field or changing meaning, type, fallback, or privacy
semantics requires a new major version. During a major transition the suite
supports at least the current and immediately previous major, and widgets may
migrate incrementally. Conformance fixtures cover compatible, absent, timed-out,
malformed, partial-failure, fallback, and privacy behavior.
