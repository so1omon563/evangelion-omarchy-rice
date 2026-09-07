# Global MAGI command palette

Press `Super + Ctrl + Alt + M` anywhere in the desktop to open the global
keyboard-first palette. Type freely, use Up/Down to select, Enter to launch,
and Escape to close. The chord is deliberately separate from Omarchy's stock
bindings and from `Super + M`, which continues to open the hierarchical MAGI
menu.

Results come from the versioned `commands.json` metadata registry plus every
installed Control Center setting and configured workspace. Matching includes
labels, categories, descriptions, IDs, and aliases. Ranking is deterministic
and never changes from usage history.

Every result shows a category and one of four safety labels:

- `safe`: launches immediately.
- `caution`: reversible but operationally significant.
- `confirm`: changes substantial system state.
- `destructive`: ends the session or powers down the machine.

Confirm and destructive actions require Enter twice. The second Enter must use
the same selected action within 60 seconds; changing the query or selection
clears the pending confirmation. Executable arguments are never returned in
search results, and execution uses argument arrays rather than a shell.

The backend can also be inspected without opening the overlay:

```bash
magi-command-palette registry
magi-command-palette search "sys helth" --json
magi-command-palette prepare system.reboot
```

Direct execution of a confirmation-required action is rejected unless it uses
the short-lived token returned by `prepare`.
