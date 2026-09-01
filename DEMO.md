# Privacy-safe demonstration mode

MAGI demonstration mode is an isolated full-interface surface for screenshots,
onboarding, visual review, and deterministic bug reproduction. It never reads
the machine's context, media, workspace, network, battery, thermal, identity,
or affinity providers. Every displayed value comes from a bundled fictional
scenario, and the persistent controller file contains only the selected
scenario name.

Open **MAGI Command Interface → Demonstration Mode → Enter / Resume Demo**.
The demonstrator covers the desktop and carries an unmistakable
`DEMONSTRATION MODE // FICTIONAL DATA // LIVE PROVIDERS DISCONNECTED` rail.
Use the adjacent menu actions to move between scenarios, capture, or exit.

```bash
magi-demo enter
magi-demo list
magi-demo scenario unit-02-offline
magi-demo next
magi-demo previous
magi-demo status --json
magi-demo capture
magi-demo exit
```

The scenario catalog covers neutral, EVA-00 prototype/refit, EVA-01, and
EVA-02 affinities plus nominal, mobile, docked, media-active, offline, manual,
constrained, and critical states. Constrained and critical each include both
thermal and battery examples.

Demo mode does not modify affinity, operating-profile, context, media, or
workspace state. Exit therefore needs no restoration transaction: it closes
the isolated overlay and resets its own selection. Captures retain the visible
demo rail and remove PNG text, EXIF, and timestamp chunks before returning.
