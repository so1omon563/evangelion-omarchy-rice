#!/usr/bin/env python3
"""Category sound, quiet-hours, preview, scene, persistence, and safety tests."""
import importlib.util,json,os,subprocess,tempfile
from importlib.machinery import SourceFileLoader
from pathlib import Path
from unittest import mock
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/"bin/magi-sound"
default=json.loads((ROOT/"omarchy/sound.json").read_text())
assert default["enabled"] is False and all(not row["enabled"] for row in default["categories"].values())
assert default["quiet_hours"]=={"enabled":True,"start":22,"end":7}
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);cfg=base/"sound.json";bindir=base/"bin";bindir.mkdir();log=base/"log"
 pw=bindir/"pw-cat";pw.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$SOUND_LOG"\ncat >/dev/null\n');pw.chmod(0o755)
 env={**os.environ,"HOME":str(base),"EVA_SOUND_CONFIG":str(cfg),"PATH":str(bindir)+":"+os.environ["PATH"],"SOUND_LOG":str(log)}
 def run(*args):return subprocess.run([str(SOURCE),*args],env=env,text=True,capture_output=True,check=True)
 initial=json.loads(run("status","--json").stdout);assert not initial["enabled"] and initial["cues"]["lock"]["reason"]=="global-kill-switch"
 run("enable");state=json.loads(run("status","--json").stdout);assert state["enabled"] and state["cues"]["lock"]["reason"]=="category-disabled"
 run("category","critical","enable");run("volume","critical","17");assert json.loads(cfg.read_text())["categories"]["critical"]=={"enabled":True,"volume_ceiling_percent":17}
 run("quiet-hours","0","23");assert json.loads(cfg.read_text())["quiet_hours"]=={"enabled":True,"start":0,"end":23}
 run("preview","critical");assert "--volume 0.17" in log.read_text()
 run("scene","unit-02","workflow","enabled");assert json.loads(cfg.read_text())["scene_overrides"]["unit-02"]["workflow"]=="enabled"
 run("scene","unit-02","workflow","inherit");assert "unit-02" not in json.loads(cfg.read_text())["scene_overrides"]
 run("kill");assert not json.loads(run("status","--json").stdout)["enabled"]
 assert cfg.stat().st_mode&0o777==0o600
spec=importlib.util.spec_from_loader("magi_sound",SourceFileLoader("magi_sound",str(SOURCE)));module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
value=json.loads(json.dumps(module.DEFAULT));value["enabled"]=True;value["categories"]["session"]["enabled"]=True
with mock.patch.object(module.shutil,"which",return_value="/usr/bin/pw-cat"),mock.patch.object(module,"active_scene",return_value=None):
 assert module.decision("lock",value,hour=23)["reason"]=="quiet-hours" and module.decision("lock",value,hour=12)["reason"]=="audible"
value["scene_overrides"]={"quiet-scene":{"session":"disabled"}}
with mock.patch.object(module.shutil,"which",return_value="/usr/bin/pw-cat"),mock.patch.object(module,"active_scene",return_value="quiet-scene"):
 assert module.decision("lock",value,hour=12)["reason"]=="category-disabled"
assert "magi-sound nominal" in (ROOT/"bin/magi-boot-sequence").read_text()
assert "omarchy-notification-send" in (ROOT/"bin/magi-battery-alert").read_text()
print("PASS  opt-in categorized sound quiet-hours preview scene precedence persistence and visual equivalents")
