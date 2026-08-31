# Responsive layout support

Evangelion Rice computes layout in logical pixels after output scaling. The
automated matrix covers 1366×768 and 1920×1080 at 1×, 2560×1440 logical at
1.25×, 4K at 2×, ultrawide at 1.5×, a vertical output, and a small secondary
display with a non-zero monitor origin.

## Fallback behavior

- Below 1600 logical pixels, bar labels collapse before status and safety
  indicators. Cava narrows and named workspaces use compact cells.
- Below 1200 logical pixels, workspace cells fall back to numeric labels.
- Transient OSDs target Hyprland's focused monitor, stay at least 16 logical
  pixels inside its bounds, and elide secondary text when narrow.
- Lock, notification, clipboard, idle, and alert surfaces clamp to the output's
  logical dimensions. The lock view uses reduced spacing below 700×600.
- Presentation panes retain at least 280×180 logical pixels, cap at 760 pixels
  wide on ultrawide displays, and switch to the compact profile below 1200
  logical pixels. Both panes use the focused monitor's origin.

The supported minimum is 320×480 logical pixels for shell overlays and
1280×720 logical pixels for the two-pane presentation. Smaller presentation
targets should use the normal terminal workflow instead of presentation mode.

Run the reproducible geometry/visual-policy fixtures with:

```bash
./tests/responsive-layouts.py test-results/responsive-layouts.json
```

The JSON output records exact panel rectangles for regression comparison and is
retained by GitHub Actions with the clean-user report.
