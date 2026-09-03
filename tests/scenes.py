#!/usr/bin/env python3
"""Affinity scene preview, authority, audio interlock, degradation, and rollback."""
import json, os, subprocess, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1];BIN=ROOT/"bin/magi-scene"
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);home=base/"home";config=home/".config/omarchy";state=base/"state";commands=base/"bin"
 config.mkdir(parents=True);commands.mkdir();backgrounds=state/"omarchy/current/theme/backgrounds";backgrounds.mkdir(parents=True)
 scenes=json.loads((ROOT/"omarchy/scenes.json").read_text());scenes["scenes"][4]["sound"]="enabled"
 for mode in ("full","reduced","off"):
  scenes["scenes"].append({"id":"motion-"+mode,"label":"Motion "+mode,"wallpaper":"2-eva-unit-01.png","affinity":"unit-01","terminal":"eva-01","sound":"keep","ambient":"keep","motion":mode})
 (config/"scenes.json").write_text(json.dumps(scenes));(config/"evangelion.json").write_text(json.dumps({"ambient":{"enabled":True},"motion":{"mode":"full"}}))
 for name in ("1-nerv-command.png","2-eva-unit-01.png","3-magi-tokyo3.png","5-eva-unit-00-prototype.png","6-eva-unit-00-refit.png","7-eva-unit-02.png"):(backgrounds/name).touch()
 current=backgrounds/"2-eva-unit-01.png";(state/"omarchy/current").mkdir(parents=True,exist_ok=True);(state/"omarchy/current/background").symlink_to(current)
 stub='''#!/bin/sh
name=$(basename "$0")
printf '%s %s\n' "$name" "$*" >> "$SCENE_LOG"
case "$name:$1" in
 magi-affinity:status) printf 'mode=auto\nactive=unit-01\n';;
 eva-terminal-profile:status) printf 'eva-01\n';;
 magi-sound:status) printf 'disabled\n';;
 magi-motion:status) printf 'full\n';;
esac
if [ "$SCENE_FAIL_ONCE" = "1" ] && [ "$name" = eva-terminal-profile ] && [ "$1" = unit-02 ] && [ ! -e "$SCENE_FAIL_MARK" ]; then touch "$SCENE_FAIL_MARK"; exit 1; fi
exit 0
'''
 for name in ("omarchy","magi-affinity","eva-terminal-profile","magi-sound","magi-ambient","magi-motion","omarchy-shell"):
  path=commands/name;path.write_text(stub);path.chmod(0o755)
 log=base/"commands.log";env={**os.environ,"PATH":str(commands)+":"+os.environ["PATH"],"EVA_SCENE_HOME":str(home),"XDG_CONFIG_HOME":str(home/".config"),"XDG_STATE_HOME":str(state),"EVA_SCENE_DATA":str(ROOT),"SCENE_LOG":str(log),"SCENE_FAIL_ONCE":"0","SCENE_FAIL_MARK":str(base/"failed")}
 def run(*args,ok=True,extra=None):
  result=subprocess.run([str(BIN),*args],env={**env,**(extra or {})},text=True,capture_output=True)
  if ok:assert result.returncode==0,result.stderr
  return result
 before=list((state/"evangelion-rice").glob("**/*")) if (state/"evangelion-rice").exists() else []
 plan=json.loads(run("preview","unit-01").stdout);assert plan["authority"]=="manual" and not before and not (state/"evangelion-rice/scenes").exists()
 assert run("apply","unit-01","--confirm","wrong",ok=False).returncode!=0
 blocked=json.loads(run("preview","unit-02").stdout);sound=next(x for x in blocked["actions"] if x["component"]=="sound");assert sound["status"]=="blocked"
 run("authorize-audio","enable");allowed=json.loads(run("preview","unit-02").stdout);assert next(x for x in allowed["actions"] if x["component"]=="sound")["status"]=="available"
 applied=json.loads(run("apply","unit-01","--confirm",plan["plan_id"]).stdout);assert applied["authority"]=="manual" and "sound" in applied["skipped"]
 assert json.loads(run("status").stdout)["authority"]=="manual"
 run("undo");assert json.loads(run("status").stdout)["authority"]=="auto"
 for mode in ("full","reduced","off"):
  motion_plan=json.loads(run("preview","motion-"+mode).stdout);run("apply","motion-"+mode,"--confirm",motion_plan["plan_id"]);run("undo")
 assert all("magi-motion set "+mode in log.read_text() for mode in ("full","reduced","off"))
 failed_plan=json.loads(run("preview","unit-02").stdout);failure=run("apply","unit-02","--confirm",failed_plan["plan_id"],ok=False,extra={"SCENE_FAIL_ONCE":"1"})
 assert "previous state restored" in failure.stderr and "magi-affinity auto" in log.read_text()
 run("auto");assert json.loads(run("status").stdout)["authority"]=="auto"
 hostile=config/"scenes.json";hostile.write_text(json.dumps({"schema_version":1,"scenes":[{"id":"bad","wallpaper":"../bad.png","affinity":"unit-01","terminal":"eva-01"}]}));assert run("status",ok=False).returncode!=0

source=(ROOT/"bin/magi-affinity").read_text();assert "MAGI_SCENE_TRANSACTION" in source and "magi-scene sync --from-affinity" in source
qml=(ROOT/"omarchy/plugins/evangelion.scene-editor/Service.qml").read_text()
for phrase in ("WlrKeyboardFocus.Exclusive","magi-scene","Key_Return","Key_A","Key_U","Key_T","Motion.MotionState","Localization.I18n","AUDIO // INTERLOCKED"):assert phrase in qml
assert "letterSpacing:" not in qml.replace("font.letterSpacing:", "")
shell=json.loads((ROOT/"omarchy/shell.json").read_text());assert any(x["id"]=="evangelion.scene-editor" for x in shell["plugins"])
plugin_manifest=json.loads((ROOT/"omarchy/plugins/evangelion.scene-editor/manifest.json").read_text());assert plugin_manifest["schemaVersion"]==1 and plugin_manifest["keepLoaded"] is True
manifest=json.loads((ROOT/"omarchy/snapshot-manifest.json").read_text());assert any(x["path"]=="omarchy/scenes.json" for x in manifest["components"]["settings"])
print("PASS  atomic affinity scenes authority audio interlock degradation rollback and editor")
