# Offline and unavailable behavior

Every optional surface follows the same state contract: `fresh`, `stale`,
`offline`, `unavailable`, or `disabled`. A missing provider is not a startup
failure. Calls have a three-second default timeout, retries back off from 15
seconds to five minutes, and cached values are shown only inside the bounds in
`~/.config/omarchy/resilience.json`.

The start page labels cached weather with its age and stops showing it after six
hours. Communications distinguishes an offline link from an unavailable probe.
Media reports an unavailable local MPRIS source without retry loops. Context and
suite-update state retain bounded freshness metadata. Remote artwork remains
opt-in through `~/.config/omarchy/media.json` and is never required.

The resilience policy is installed with the `shell` component and preserved on
upgrade. Inspect the complete contract without contacting any provider:

```bash
magi-resilience
magi-resilience --json
```

The status command reads timestamps only. It does not persist SSIDs, routes,
track metadata, context facts, or remote artwork. Removing a cache is safe; its
surface moves to `unavailable` until a provider publishes a fresh value.

## Testing degraded states

Run `python3 tests/resilience.py`. For a visual check, disconnect networking and
reload the start page. Weather will show a bounded cached reading with `AGE`, or
`LINK UNAVAILABLE`; the communications panel will show `OFFLINE` or
`UNAVAILABLE` with its reason. Automated tests do not disconnect the network.
