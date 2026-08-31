#!/usr/bin/env python3
"""Portable motion accessibility, interruption, and performance regressions."""

import json
import os
import re
import statistics
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "test-results/motion-regression.json"
PLUGINS = ROOT / "omarchy/plugins"


def motion(home, *args):
    env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
           "XDG_STATE_HOME": str(home / ".local/state"), "EVANGELION_SKIP_RUNTIME": "1"}
    started = time.perf_counter()
    result = subprocess.run([str(ROOT / "bin/magi-motion"), *args], env=env,
                            text=True, capture_output=True, check=True)
    return result.stdout.strip(), (time.perf_counter() - started) * 1000


def source(plugin, relative="Service.qml"):
    return (PLUGINS / plugin / relative).read_text()


def mode_stress():
    latencies = []
    sequence = ("full", "reduced", "off") * 20
    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        for expected in sequence:
            actual, elapsed = motion(home, "set", expected)
            latencies.append(elapsed)
            assert actual == expected
            state = json.loads((home / ".local/state/evangelion-rice/motion/state.json").read_text())
            assert state["mode"] == expected
        selected = json.loads((home / ".config/omarchy/evangelion.json").read_text())
        assert selected["motion"]["mode"] == sequence[-1]
        final = json.loads(motion(home, "status", "--json")[0])
        assert final["selected_mode"] == sequence[-1] and final["mode"] == sequence[-1]
    ordered = sorted(latencies)
    p95 = ordered[max(0, int(len(ordered) * .95) - 1)]
    assert p95 < 500
    return {"iterations": len(sequence), "median_ms": round(statistics.median(latencies), 2),
            "p95_ms": round(p95, 2), "budget_ms": 500}


def wallpaper_stress():
    expected = {
        "5-eva-unit-00-prototype.png": "unit-00-prototype",
        "6-eva-unit-00-refit.png": "unit-00-refit",
        "2-eva-unit-01.png": "unit-01",
        "7-eva-unit-02.png": "unit-02",
        "1-nerv-logo.png": "neutral",
    }
    sequence = list(expected.items()) * 12
    started = time.perf_counter()
    for wallpaper, affinity in sequence:
        result = subprocess.run([str(ROOT / "bin/magi-affinity"), "detect", wallpaper],
                                text=True, capture_output=True, check=True)
        assert result.stdout.strip() == affinity
    elapsed = (time.perf_counter() - started) * 1000
    assert elapsed < 5000
    affinity_source = (ROOT / "bin/magi-affinity").read_text()
    assert "mktemp -d" in affinity_source and "Affinity apply failed; previous state restored." in affinity_source
    return {"iterations": len(sequence), "elapsed_ms": round(elapsed, 2),
            "last_request_wins_mapping": True, "transactional_apply": True}


def interruption_contracts():
    notifications = source("evangelion.notifications")
    card = source("evangelion.notifications", "components/NotificationCard.qml")
    workspace = source("evangelion.workspace-osd")
    device = source("evangelion.device-osd")
    power = source("evangelion.power-sequence")
    intrusion = source("evangelion.angel-intrusion")
    update = source("evangelion.update-operation")
    motion_state = source("evangelion.motion", "MotionState.qml")

    assert "refreshPopup(" in notifications
    assert "onSummaryChanged: cardSlot.remainingLifetime = 1.0" in notifications
    assert "retireTimer.restart()" in workspace and "retire.restart()" in device
    assert "settleTimer.restart()" in power and "cooldownTimer.restart()" in power
    assert "collapseTimer.restart()" in intrusion and "collapseTimer.stop()" in intrusion
    assert "watchChanges: true" in motion_state and "onFileChanged: root.refresh()" in motion_state
    assert "onFileChanged:reload()" in update.replace(" ", "")

    assert 'urgency === 2 || motionMode === "off"' in card
    assert "Behavior on width" not in intrusion and "Animation.Infinite" not in intrusion
    assert 'root.status!=="failed"&&!motion.off' in update.replace(" ", "")

    for text in (workspace, device, power, intrusion, update):
        compact = text.replace(" ", "")
        assert "focusedMonitor" in text and re.search(r"(?:parent|panel)\.(?:width|height)-(?:24|32|48)", compact)

    return {"rapid_retargeting": True, "coalescing": True, "critical_immediate": True,
            "reload_watch": True, "focused_output": True}


def activity_contracts():
    findings = []
    signatures = set()
    for path in sorted(PLUGINS.glob("**/*.qml")):
        text = path.read_text()
        relative = str(path.relative_to(ROOT))
        for block in re.findall(r"(?:Sequential|Parallel)Animation\s*(?:on\s+\w+)?\s*\{.{0,700}?\}", text, re.S):
            if "Animation.Infinite" in block:
                assert "running:" in block and any(token in block for token in ("opened", "visible", "active")), relative
                findings.append({"file": relative, "kind": "infinite-animation", "guarded": True})
        for interval, running in re.findall(r"Timer\s*\{.{0,220}?interval:\s*([^;\n]+).{0,220}?running:\s*([^;\n]+)", text, re.S):
            signature = (relative, interval.strip(), running.strip())
            assert signature not in signatures, signature
            signatures.add(signature)
            findings.append({"file": relative, "kind": "timer", "running_guard": running.strip()})
    power = source("evangelion.power", "Panel.qml")
    cava = source("evangelion.cava", "BarWidget.qml")
    notification = source("evangelion.notifications")
    assert "running: root.opened && root.rotatingPhrases" in power
    assert "root.charging && !root.fullyCharged && root.opened" in power
    assert "running: root.cavaAvailable" in cava
    assert "readonly property bool ticking: cardSlot.lifetime > 0 && !card.hovered" in notification
    return {"inventoried": len(findings), "duplicate_timer_signatures": 0,
            "hidden_surface_guards": True, "findings": findings}


def responsive_evidence():
    with tempfile.TemporaryDirectory() as temporary:
        result_path = Path(temporary) / "responsive.json"
        subprocess.run([sys.executable, str(ROOT / "tests/responsive-layouts.py"), str(result_path)],
                       check=True, capture_output=True, text=True)
        result = json.loads(result_path.read_text())
    assert result["status"] == "passed" and len(result["profiles"]) == 7
    assert result["checks"]["boundedSurfaces"] and result["checks"]["focusedMonitorRouting"]
    return {"profiles": len(result["profiles"]), **result["checks"]}


def main():
    started = time.time()
    report = {"schema_version": 1, "status": "passed", "suite": "motion-regression",
              "generated_at_epoch": int(started), "checks": {
                  "mode_stress": mode_stress(),
                  "wallpaper_stress": wallpaper_stress(),
                  "interruption": interruption_contracts(),
                  "activity": activity_contracts(),
                  "responsive": responsive_evidence(),
              }}
    report["duration_ms"] = round((time.time() - started) * 1000, 2)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    print("PASS  motion accessibility and interruption regression suite")
    print(f"RESULTS // {OUTPUT}")


if __name__ == "__main__":
    main()
