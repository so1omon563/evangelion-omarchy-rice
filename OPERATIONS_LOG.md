# MAGI operations log

The operations log is a private, local, searchable history of notifications and
important MAGI state changes. Open it with `Super + Ctrl + Alt + O`, or select
**Operations log** from the global command palette. It remains useful offline
and does not send telemetry.

Type to search. Use Up/Down to select, Enter to invoke an allowlisted safe
action, `E` to export a sanitized JSON copy, `C` twice to clear the archive,
and Escape to close. Export defaults to `~/Downloads/magi-operations-log.json`.

The archive excludes HTML, credentials, bearer values, email addresses, IP
addresses, and the local home path before writing. Unknown actions are discarded.
Repeated events are coalesced. The default policy retains at most 250 records,
14 days, or 1 MiB—whichever boundary is reached first—in mode-0600 files under
`~/.local/state/evangelion-rice/operations-log/`.

The preserved policy is `~/.config/omarchy/operations-log.json`. Change its
bounded retention values with:

```sh
magi-operations-log retention 500 30 2097152
```

Inspect without opening the panel using `magi-operations-log status` or
`magi-operations-log search QUERY`. Clearing requires the short-lived token
returned by `magi-operations-log clear-plan`; scripts cannot clear history by
accident. If the index or an action provider is unavailable, the start page and
panel degrade to local fallback state instead of blocking the desktop.
