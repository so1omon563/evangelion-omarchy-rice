#!/usr/bin/env python3
"""Bounded persistence, calm defaults, safety visibility, input, and layout contracts."""
import json,os,stat,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];CLI=ROOT/"bin/magi-disclosure";DEFAULT=ROOT/"omarchy/disclosure.json"
with tempfile.TemporaryDirectory() as raw:
 config=Path(raw)/"disclosure.json";env={**os.environ,"EVA_DISCLOSURE_CONFIG":str(config)}
 def run(*args,ok=True):
  value=subprocess.run([str(CLI),*args],env=env,text=True,capture_output=True)
  if ok:assert value.returncode==0,value.stderr
  return value
 def value(*args):return json.loads(run(*args).stdout)
 initial=value("status");assert initial["bounded"] is True and set(initial["surfaces"].values())=={"compact"}
 toggled=value("toggle","context");assert toggled["mode"]=="details" and stat.S_IMODE(config.stat().st_mode)==0o600
 assert value("status","context")["mode"]=="details" and value("set","health","details")["mode"]=="details"
 assert run("set","context","verbose",ok=False).returncode!=0 and run("toggle","unknown",ok=False).returncode!=0
 reset=value("reset");assert set(reset["surfaces"].values())=={"compact"}
 config.write_text('{"schema_version":1,"surfaces":{"context":"hidden"}}');assert run("status",ok=False).returncode!=0

context=(ROOT/"omarchy/plugins/evangelion.context/BarWidget.qml").read_text();health=(ROOT/"omarchy/plugins/evangelion.health/BarWidget.qml").read_text();ops=(ROOT/"omarchy/plugins/evangelion.operations-log/Service.qml").read_text();html=(ROOT/"start-page/index.html").read_text();js=(ROOT/"start-page/app.js").read_text();css=(ROOT/"start-page/style.css").read_text();server=(ROOT/"start-page/server.py").read_text()
for source,surface in ((context,"context"),(health,"health"),(ops,"operations-log")):
 assert "magi-disclosure" in source and surface in source
 assert "height:Style.space(44)" in source if surface!="operations-log" else "Layout.preferredHeight:44" in source
assert 'row.tier==="warning"||row.tier==="critical"' in health
assert "root.statusTitle()" in context and "derived_state?.summary" in context and "root.safeRecommendations()" in context
assert "Qt.Key_D" in context and "Qt.Key_D" in ops and "activeFocusOnTab:true" in health
assert "Motion.MotionPopupCard" in context and "Motion.MotionPopupCard" in health
assert 'aria-expanded="false"' in html and "min-height:44px" in css and ".telemetry-details[hidden]" in css
assert "/api/disclosure/toggle" in server and '"disclosure": disclosure_surface()' in server and "TOGGLE TELEMETRY DETAILS" in js
assert "data.thermal.tier" in js and "data.network.reason" in js and "data.context?.status" in js
manifest=json.loads((ROOT/"omarchy/snapshot-manifest.json").read_text());assert any(item["path"]=="omarchy/disclosure.json" for item in manifest["components"]["settings"])
print("PASS  progressive telemetry disclosure preserves compact geometry safety visibility keyboard touch persistence responsiveness and motion modes")
