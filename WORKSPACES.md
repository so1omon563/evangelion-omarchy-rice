# Workspace Identities

Open **MAGI Control Center** and press `W`, or choose **Workspace Identities**
from the MAGI menu. The editor changes the full identity, compact token, and
OSD operations channel without hand-editing configuration. Up/Down selects a
workspace, Tab moves through fields, `Ctrl+S` saves, `Ctrl+R` refreshes, and
Escape closes.

The bar reads `~/.config/omarchy/workspaces.json` live. At 2000 physical pixels
and wider it shows a bounded full identity; from 1200–1999 it shows the numeric ID
and compact token; below 1200 and on vertical bars it shows only the numeric
workspace. Tooltips and the transition OSD always retain the full name. If two
workspaces request the same compact token, `magi-workspaces` adds a stable
numeric disambiguator rather than showing ambiguous labels.

The file uses versioned schema 1 and contains only workspace IDs, display
names, compact tokens, channels, and colors. Names and channels are bounded,
control characters are rejected, and IDs must be unique integers from 1–10.
Changes trigger a live bar and OSD refresh.

## Portable import and export

Exports contain no host paths, device IDs, accounts, or private desktop state.
Import is preview-first and captures a named settings snapshot before applying:

```bash
magi-workspaces status --json --width 1366
magi-workspaces set 4 "ENTRY PLUG · DEVELOPMENT" --short ENT \
  --channel "EVA INTERFACE · BUILD CHANNEL"
magi-workspaces export ./my-workspaces.json
magi-workspaces import ./my-workspaces.json
magi-workspaces import ./my-workspaces.json --confirm PLAN_ID_FROM_PREVIEW
magi-workspaces reset
```

Named configuration snapshots include `workspaces.json`, so it can also be
restored selectively with the existing settings snapshot component.
