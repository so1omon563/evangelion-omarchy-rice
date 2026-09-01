#!/usr/bin/env python3
"""Acceptance coverage for the opt-in MAGI developer performance overlay."""

import json
import os
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-performance"

def executable(path,body):
    path.write_text("#!/bin/sh\n"+body+"\n"); path.chmod(path.stat().st_mode|stat.S_IXUSR)

with tempfile.TemporaryDirectory() as directory:
    base=Path(directory); home=base/"home"; fake=base/"bin"; config=home/".config/omarchy/performance.json"; state=base/"state"
    fake.mkdir(parents=True); config.parent.mkdir(parents=True)
    config.write_text(json.dumps({"schema_version":1,"enabled":False,"sample_interval_ms":10,"probe_timeout_ms":80,"maximum_components":3,"maximum_samples":16}))
    for name in ("magi-health","magi-context","magi-extension-state"):
        executable(fake/name,"printf 'PRIVATE-PAYLOAD-SENTINEL\\n'")
    executable(fake/"magi-motion","sleep 1; printf '{}\\n'")
    env={**os.environ,"HOME":str(home),"PATH":f"{fake}:/usr/bin:/bin","EVA_PERFORMANCE_CONFIG":str(config),"EVA_PERFORMANCE_STATE_DIR":str(state)}
    def run(*args,check=True): return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=check,timeout=3)

    disabled=json.loads(run("sample","--json").stdout)
    assert disabled["enabled"] is False and disabled["samples"]==0 and not (state/"aggregate.json").exists()
    assert json.loads(config.read_text())["sample_interval_ms"]==10, "read-only status must not rewrite user configuration"
    assert run("toggle").stdout.strip()=="enabled"
    reports=[json.loads(run("sample","--json").stdout) for _ in range(20)]
    final=reports[-1]
    assert final["enabled"] is True and final["samples"]==16
    assert len(final["components"])==3 and sum(row["samples"] for row in final["components"])<=16
    assert all(row["refresh_hz"]>0 for report in reports for row in report["components"])
    assert any(row["availability"]=="timed-out" for report in reports for row in report["components"])
    assert final["sample_interval_ms"]==1000 and final["privacy"]=={"payload_capture":False,"aggregate_only":True}
    export=base/"report.json"; run("export",str(export)); serialized=export.read_text().lower()
    assert "private-payload-sentinel" not in serialized
    for prohibited in (str(home).lower(),"stdout","stderr","command_line","window_title","hostname","username","ssid","\"pid\""):
        assert prohibited not in serialized
    assert stat.S_IMODE((state/"aggregate.json").stat().st_mode)==0o600 and stat.S_IMODE(export.stat().st_mode)==0o600
    assert run("disable").stdout.strip()=="disabled" and json.loads(run("status","--json").stdout)["enabled"] is False

qml=(ROOT/"omarchy/plugins/evangelion.performance/Service.qml").read_text()
manifest=json.loads((ROOT/"omarchy/plugins/evangelion.performance/manifest.json").read_text())
shell=json.loads((ROOT/"omarchy/shell.json").read_text()); bindings=(ROOT/"hypr/bindings.lua").read_text(); docs=(ROOT/"HOTKEYS.md").read_text()
assert manifest["id"]=="evangelion.performance" and manifest["keepLoaded"] is True
assert any(item["id"]=="evangelion.performance" for item in shell["plugins"])
assert 'running:root.enabled' in qml and 'root.enabled && !sampleProbe.running' in qml
assert 'Motion.MotionState' in qml and 'motion.full?180:80' in qml and 'enabled:!motion.off' in qml
assert 'payload_capture:false' in qml and 'WlrKeyboardFocus.None' in qml
assert 'refresh_hz' in qml and 'CACHE FRESHNESS' in qml and 'age_seconds' in qml
assert 'SUPER + CTRL + ALT + F' in bindings and 'magi-performance toggle' in bindings
assert 'SUPER + ALT + F' not in bindings
assert 'Super + Ctrl + Alt + F' in docs and 'disabled by default' in docs
print("PASS  disabled-idle, bounded payload-blind aggregates, export, hotkey, and motion policy")
