#!/usr/bin/env python3
import json, os, stat, subprocess, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-workspaces"
with tempfile.TemporaryDirectory() as raw:
    base=Path(raw);home=base/"home";config=home/".config/omarchy/workspaces.json";commands=base/"bin";commands.mkdir()
    fake=commands/"magi-snapshot";fake.write_text("#!/bin/sh\nexit 0\n");fake.chmod(0o755)
    env={**os.environ,"PATH":str(commands)+":"+os.environ["PATH"],"EVA_WORKSPACES_HOME":str(home),"EVA_WORKSPACES_DATA":str(ROOT),"EVA_WORKSPACES_DEFAULT":str(ROOT/"omarchy/workspaces.json"),"EVA_WORKSPACES_CONFIG":str(config),"EVA_WORKSPACES_SKIP_ACTIVATE":"1"}
    def run(*args,ok=True):
        result=subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True)
        if ok:assert result.returncode==0,result.stderr
        return result
    full=json.loads(run("status","--json","--width","2560").stdout);compact=json.loads(run("status","--json","--width","1366").stdout);minimal=json.loads(run("status","--json","--width","800").stdout)
    assert full["tier"]=="full" and compact["tier"]=="compact" and minimal["tier"]=="minimal"
    assert full["workspaces"][0]["label"]=="01·MELCHIOR" and compact["workspaces"][0]["label"]=="01·MEL" and minimal["workspaces"][0]["label"]=="1"
    changed=json.loads(run("set","1","ANALYSIS CORE","--short","OPS","--channel","LOCAL LOGIC CHANNEL").stdout)
    assert changed["name"]=="ANALYSIS CORE" and stat.S_IMODE(config.stat().st_mode)==0o644
    run("set","2","OPERATIONS CORE","--short","OPS")
    collision=json.loads(run("status","--json","--width","1366").stdout)["workspaces"]
    assert collision[0]["resolved_short"]=="OPS" and collision[1]["resolved_short"]=="OPS2" and len({x["label"] for x in collision})==len(collision)
    exported=base/"portable.json";run("export",str(exported));payload=exported.read_text();assert str(home) not in payload and "schema_version" in payload
    incoming=json.loads(exported.read_text());incoming["workspaces"][0]["name"]="IMPORTED ANALYSIS";exported.write_text(json.dumps(incoming))
    plan=json.loads(run("import",str(exported)).stdout);before=config.read_bytes();assert plan["changed"] and config.read_bytes()==before
    assert run("import",str(exported),"--confirm","wrong",ok=False).returncode!=0 and config.read_bytes()==before
    applied=json.loads(run("import",str(exported),"--confirm",plan["plan_id"]).stdout);assert applied["status"]=="imported" and "IMPORTED ANALYSIS" in config.read_text()
    hostile=base/"hostile.json";hostile.write_text(json.dumps({"schema_version":1,"workspaces":[{"id":1,"name":"BAD\nNAME","short":"BAD","channel":"X","accent":"#000000"}]}));assert run("import",str(hostile),ok=False).returncode!=0
    run("reset");assert "MELCHIOR" in config.read_text()

bar=(ROOT/"omarchy/plugins/evangelion.workspaces/Workspaces.qml").read_text();osd=(ROOT/"omarchy/plugins/evangelion.workspace-osd/Service.qml").read_text();editor=(ROOT/"omarchy/plugins/evangelion.workspace-names/Service.qml").read_text()
for phrase in ("magi-workspaces","--screen","displayWidth","QsWindow.window.screen.name","FileView","onLoaded:root.loadNames", "resolved_short","identity.name","identity.accent"):assert phrase in bar
for phrase in ("magi-workspaces","workspaceModel","workspaceCopy","channel"):assert phrase in osd
for phrase in ("WlrKeyboardFocus.Exclusive","TextInput","ControlModifier", "Key_S","maximumLength","Motion.MotionState","Localization.I18n"):assert phrase in editor
assert "omarchy/workspaces.json" in (ROOT/"omarchy/snapshot-manifest.json").read_text()
print("PASS  editable workspace schema responsive labels collisions OSD identity live refresh and portable import export")
