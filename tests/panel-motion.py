#!/usr/bin/env python3
"""Contract tests for interactive panel motion and input safety."""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "test-results/panel-motion.json"
PLUGINS = ROOT / "omarchy/plugins"


def read(plugin, relative="BarWidget.qml"):
    return (PLUGINS / plugin / relative).read_text()


def main():
    popup = read("evangelion.motion", "MotionPopupCard.qml")
    participants = ("media", "privacy", "communications", "health", "mission", "world-clock", "context")
    for name in participants:
        source = read(f"evangelion.{name}")
        assert 'import "../evangelion.motion" as Motion' in source, name
        assert "Motion.MotionPopupCard" in source, name
        assert "PopupCard" not in source.replace("Motion.MotionPopupCard", ""), name

    assert "HyprlandFocusGrab" in popup and "active: root.open" in popup
    assert "PopupAdjustment.Slide" in popup
    assert "Math.max(root.margin, Math.min" in popup
    assert "motion.off ? 140 : motion.standardMs" in popup
    assert "open && motion.full" in popup and "acquisition.stop()" in popup
    assert "scale:" not in popup and "Behavior on x" not in popup and "Behavior on y" not in popup
    assert "if (open) bar.requestPopout" in popup and "bar.releasePopout" in popup

    clipboard = read("evangelion.clipboard", "Clipboard.qml")
    assert "root.panelReady = false\n    root.opened = false" in clipboard
    assert "root.panelReady = true\n      keyCatcher.forceActiveFocus()" in clipboard
    assert "opacity: motion.off || root.panelReady ? 1 : 0" in clipboard
    assert "if (root.clearConfirmOpen)" in clipboard and "clearConfirm.handleKey(event)" in clipboard
    assert "onConfirmed: root.confirmClearHistory()" in clipboard

    power = read("evangelion.power", "Panel.qml")
    assert "running: motion.full && root.opened && root.rotatingPhrases" in power
    assert "running: motion.full && root.charging" in power
    assert "Behavior on width { enabled: motion.full" in power
    assert "focusTarget: keyCatcher" in power and "onCloseRequested: root.close()" in power

    menu = (ROOT / "omarchy/extensions/omarchy-menu.jsonc").read_text()
    hypr = (ROOT / "hypr/looknfeel.lua").read_text()
    assert '"action": "omarchy-menu summon apps"' in menu
    assert '"label":"Open Downloads Directory"' in menu
    assert menu.index('"system.logout.abort"') < menu.index('"system.logout.execute"')
    assert menu.index('"system.reboot.abort"') < menu.index('"system.reboot.execute"')
    assert menu.index('"system.shutdown.abort"') < menu.index('"system.shutdown.execute"')
    assert 'leaf = "layersIn", enabled = true' in hypr
    assert 'leaf = "layersIn", enabled = false' in hypr

    report = {"schema_version": 1, "status": "passed", "popup_participants": len(participants),
              "checks": {"anchor_safe": True, "focus_grab": True, "closing_wins": True,
                         "destructive_confirmation_stationary": True, "reduced_fade": True,
                         "off_baseline_popup": True, "bounded_geometry": True,
                         "launcher_layer_motion": True, "destructive_menu_abort_first": True}}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    print("PASS  interactive panel motion and safety contracts")
    print(f"RESULTS // {OUTPUT}")


if __name__ == "__main__":
    main()
