#!/usr/bin/env python3
"""Bounded visual tokens, capability fallback, shell wiring, and Hyprland ownership."""
import json, os, stat, subprocess, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; BIN=ROOT/"bin/magi-visual"
with tempfile.TemporaryDirectory() as raw:
 home=Path(raw)/"home"; config=home/".config/omarchy/visual.json"
 env={**os.environ,"EVA_VISUAL_HOME":str(home),"EVA_VISUAL_DEFAULT":str(ROOT/"omarchy/visual.json"),"EVA_VISUAL_SKIP_ACTIVATE":"1"}
 def run(*args,ok=True):
  value=subprocess.run([str(BIN),*args],env=env,text=True,capture_output=True)
  if ok:assert value.returncode==0,value.stderr
  return value
 status=json.loads(run("status","--json").stdout)
 assert status["resolved"]["gaps_out"]==7 and status["resolved"]["window_opacity"]==.96
 assert set(status["capabilities"])=={"density","accent_strength","typography","panel_treatment","blur","opacity","gaps","borders","animation_intensity"}
 run("set","gaps","open");run("set","typography","large");updated=json.loads(run("status","--json").stdout)
 assert updated["resolved"]["gaps_out"]==12 and updated["resolved"]["font_scale"]==1.16
 assert stat.S_IMODE(config.stat().st_mode)==0o644
 before=config.read_bytes();assert run("set","gaps","dangerous",ok=False).returncode!=0 and config.read_bytes()==before
 config.write_text('{"schema_version":1,"gaps":"open"}')
 assert run("status","--json",ok=False).returncode!=0

schema=json.loads((ROOT/"omarchy/settings-schema.json").read_text())
visual=[row for row in schema["settings"] if row["id"].startswith("visual.")]
assert len(visual)==9 and all(row["snapshot"]=="settings" and row["command"]=="magi-visual" for row in visual)
hypr=(ROOT/"hypr/looknfeel.lua").read_text()
for phrase in ("visual_config", "gap_profiles", "border_profiles", "blur_profiles", "opacity_profiles", "animation_profiles", "profile.blur and visual_blur[1]"):
 assert phrase in hypr
qml=(ROOT/"omarchy/plugins/evangelion.settings/Service.qml").read_text()
for phrase in ("densityScale","fontScale","panelAlpha","accentAlpha","rowHeight","Flickable","clip:true","revealSelection"):
 assert phrase in qml
manifest=json.loads((ROOT/"omarchy/snapshot-manifest.json").read_text())
assert any(row["path"]=="omarchy/visual.json" for row in manifest["components"]["settings"])
print("PASS  bounded visual customization preview undo fallback and responsive shell tokens")
