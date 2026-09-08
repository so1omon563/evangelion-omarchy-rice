# Progressive telemetry disclosure

MAGI surfaces start calm and compact. Rich diagnostic fields remain one action
away in the context inspector, system-health panel, operations log, and start
page telemetry card. Each surface remembers Compact or Details independently in
the preserved `~/.config/omarchy/disclosure.json` file.

Use the visible **Details** control with mouse, touch, Tab plus Enter/Space, or
press `D` inside the context and operations-log panels. The start page also
offers **Toggle telemetry details** in its `/` command palette. Controls retain
a minimum 44-pixel target and expanded content stays within each surface's
existing responsive scroll or grid boundary.

Progressive disclosure never hides warnings, critical readings, remediation,
the primary status, or the reason for an unsafe state. In Compact mode, the
health panel removes only nominal sensor rows; the context surface retains its
state, summary, freshness, conclusion, and safe recommendations. Motion comes
from the existing shared popup policy, so Full, Reduced, and Off modes behave
consistently and disclosure itself adds no flashing or decorative motion.

For scripting and recovery:

```sh
magi-disclosure status
magi-disclosure toggle context
magi-disclosure set health details
magi-disclosure reset
```

Only the four named surfaces and the two modes `compact` and `details` are
accepted. Invalid or partially written policies fail closed instead of silently
inventing display state.
