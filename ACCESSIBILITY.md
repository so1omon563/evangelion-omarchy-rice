# Accessibility and inclusive interaction

Evangelion Rice targets keyboard-complete operation, readable contrast, bounded
motion, resilient scaling, and useful assistive names without changing
Omarchy's security or session model. These requirements apply to every new or
modified v1.5 surface.

## Standards

- Normal text targets WCAG 2.x AA contrast of at least 4.5:1; large text and
  meaningful non-text indicators target at least 3:1. Muted purple below that
  threshold is reserved for borders and decoration, never required content.
- Interactive controls target at least 32 logical pixels. Compact bar widgets
  may be 28 pixels wide because the full bar thickness supplies a 38-pixel
  target and the same action is available through keyboard or CLI.
- Layouts are tested at 1.0, 1.25, 1.5, and 2.0 scale, including 1280×720,
  portrait, laptop, ultrawide, and multi-monitor fixtures. Text must wrap,
  elide, or scroll rather than overlap or escape its surface.
- Full motion may use short fades and bounded travel. Reduced removes repeated
  or decorative motion. Off changes state immediately. Safety and privacy
  meaning never depends on animation, and no surface flashes three times per
  second or faster.
- Actionable panels do not auto-dismiss. Transient OSDs may time out because
  they do not own the underlying state; persistent status and CLI inspection
  remain available.
- Selection, state, and severity use words or glyphs in addition to color.
  Destructive actions require an explicit confirmation or narrowly scoped
  command.

## Keyboard and assistive technology

The Control Center, workspace editor, affinity scene editor, context inspector,
media panel, clipboard, power panel, lock screen, menus, and destructive
confirmations are keyboard operable. Shared MAGI popups accept Escape even
when their individual widget has no custom key map. Every command exposed by a
pointer-only convenience control also has a documented CLI or global shortcut.

Interactive MAGI bar widgets publish Qt Accessibility button names and
descriptions. Shared popups publish a dialog role; the three full-screen editors
announce their current selection; the lock password field publishes an editable
text role without exposing its value. Actual spoken output depends on Qt,
Quickshell, the Wayland accessibility bridge, and the user's screen reader.

Useful keyboard routes are documented in [HOTKEYS.md](HOTKEYS.md). The complete
automated matrix runs through `python3 tests/accessibility.py` and `./validate.sh`.

## Documented platform exceptions

- Quickshell/Wayland does not currently guarantee a complete AT-SPI tree for
  every Canvas, layer-shell surface, or upstream Omarchy control. MAGI adds
  semantics where Qt exposes them and retains textual/CLI parity elsewhere.
- Cava's bars, acquisition rails, wallpaper art, and NERV decorative marks are
  ignored as meaning-bearing content; adjacent text communicates their state.
- The suite does not override OS-level font DPI, screen-reader configuration,
  color filters, or input-device preferences.
- Vendor tray icons belong to upstream applications. Their accessible behavior
  is governed by the StatusNotifier host and source application.

Accessibility regressions are release blockers when they hide safety state,
prevent a documented keyboard workflow, drop required text below the contrast
floor, trap focus, expose a password, or make a supported display unusable.
