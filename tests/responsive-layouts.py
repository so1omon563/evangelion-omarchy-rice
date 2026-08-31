#!/usr/bin/env python3
"""Exercise presentation geometry and responsive QML policy markers."""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests/fixtures/responsive-layouts.json"
OUTPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "test-results/responsive-layouts.json"


def geometry(monitor):
    result = subprocess.run(
        [str(ROOT / "bin/magi-presentation"), "--print-geometry", json.dumps(monitor), "left", "43", "38"],
        text=True, capture_output=True, check=True,
    )
    return json.loads(result.stdout)


def check_profile(profile):
    monitor = profile["monitor"]
    calculated = geometry(monitor)
    screen = calculated["screen"]
    assert calculated["fallback"] == profile["fallback"]
    assert screen["logicalWidth"] == int(monitor["width"] / monitor["scale"])
    assert screen["logicalHeight"] == int(monitor["height"] / monitor["scale"])
    assert screen["scale"] == monitor["scale"]
    left, top = monitor["x"], monitor["y"]
    right, bottom = left + screen["logicalWidth"], top + screen["logicalHeight"]
    for panel_name in ("fastfetch", "btop"):
        panel = calculated[panel_name]
        assert panel["width"] >= 280 and panel["height"] >= 180
        assert left <= panel["x"] and panel["x"] + panel["width"] <= right
        assert top <= panel["y"] and panel["y"] + panel["height"] <= bottom
    assert calculated["fastfetch"]["width"] <= 760
    assert calculated["btop"]["y"] > calculated["fastfetch"]["y"] + calculated["fastfetch"]["height"]
    return {"name": profile["name"], "status": "passed", "geometry": calculated}


def source_checks():
    workspaces = (ROOT / "omarchy/plugins/evangelion.workspaces/Workspaces.qml").read_text()
    lock = (ROOT / "omarchy/plugins/evangelion.lock/LockView.qml").read_text()
    notifications = (ROOT / "omarchy/plugins/evangelion.notifications/components/NotificationCard.qml").read_text()
    assert "minimalBar" in workspaces and "compactBar" in workspaces
    assert "parent.width - 32" in lock and "parent.height - 48" in lock
    assert "Screen.width - Style.space(24)" in notifications
    for plugin in ("workspace-osd", "device-osd", "power-sequence", "magi-idle", "angel-intrusion", "update-operation"):
        source = (ROOT / f"omarchy/plugins/evangelion.{plugin}/Service.qml").read_text()
        assert "focusedMonitor" in source and "screen: root.targetScreen" in source.replace("screen:root", "screen: root")


def main():
    fixture = json.loads(FIXTURES.read_text())
    assert fixture["schema_version"] == 1
    scales = {item["monitor"]["scale"] for item in fixture["profiles"]}
    assert {1.0, 1.25, 1.5, 2.0}.issubset(scales)
    assert any(item["monitor"]["height"] > item["monitor"]["width"] for item in fixture["profiles"])
    source_checks()
    profiles = [check_profile(profile) for profile in fixture["profiles"]]
    report = {"schema_version": 1, "status": "passed", "profiles": profiles,
              "checks": {"barFallbacks": True, "boundedSurfaces": True, "focusedMonitorRouting": True}}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"PASS  responsive geometry matrix ({len(profiles)} profiles)")
    print(f"RESULTS // {OUTPUT}")


if __name__ == "__main__":
    main()
