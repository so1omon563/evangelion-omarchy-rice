#!/usr/bin/env python3
"""Static contracts for the responsive, privacy-bounded context inspector."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "omarchy/plugins/evangelion.context/BarWidget.qml").read_text()
SHELL = json.loads((ROOT / "omarchy/shell.json").read_text())
MENU = (ROOT / "omarchy/extensions/omarchy-menu.jsonc").read_text()
BINDINGS = (ROOT / "hypr/bindings.lua").read_text()


def main():
    assert any(item["id"] == "evangelion.context" for item in SHELL["bar"]["layout"]["right"])
    assert 'target: "magi-context-inspector"' in SOURCE
    assert '["magi-context","status","--json","--compact"]' in SOURCE
    assert '["magi-context","refresh","--json","--compact"]' in SOURCE
    assert "Timer {" not in SOURCE, "inspector added background collection"
    assert 'Motion.MotionPopupCard' in SOURCE and 'fittedContentWidth' in SOURCE and 'fittedContentHeight' in SOURCE
    assert "centerOnBar:true" in SOURCE and "Math.min(contentColumn.implicitHeight" in SOURCE
    assert "};" not in SOURCE, "QML property group has a trailing semicolon"
    assert "Flickable" in SOURCE and "clip:true" in SOURCE
    assert "FocusScope" in SOURCE and "forceActiveFocus" in SOURCE
    assert "Keys.onEscapePressed" in SOURCE and "Qt.Key_Return" in SOURCE and "Qt.Key_Space" in SOURCE
    for state in ("CONTEXT UNKNOWN", "CONTEXT UNAVAILABLE", "CONTEXT DISABLED"):
        assert state in SOURCE
    assert 'safeFacts:' in SOURCE and 'signalNames:' in SOURCE
    assert "context.facts" not in SOURCE and "raw" not in SOURCE.lower()
    assert "confidence" not in SOURCE.lower(), "opaque confidence is rendered"
    assert 'item.action !== "select-operating-profile"' in SOURCE
    assert '["docked", "mobile"].indexOf(item.target) < 0' in SOURCE
    assert "safeRecommendations" in SOURCE and "model:root.safeRecommendations()" in SOURCE
    assert "automatic_actions" in SOURCE
    assert "HELD // MANUAL PROFILE" in SOURCE and "ACTION QUEUED" in SOURCE
    assert '"magi.context.panel"' in MENU and '"magi.context.refresh"' in MENU
    assert "SUPER + CTRL + ALT + G" in BINDINGS
    assert "SUPER + ALT + G" not in BINDINGS
    print("PASS  responsive privacy-bounded MAGI context inspector")


if __name__ == "__main__":
    main()
