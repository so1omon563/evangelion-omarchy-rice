#!/usr/bin/env python3
import json,os,stat,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];CMD=ROOT/"bin/magi-machine-profile"
with tempfile.TemporaryDirectory() as raw:
 b=Path(raw);home=b/"home";config=b/"config/omarchy";state=b/"state";fake=b/"hyprctl";fixture=b/"monitors.json";empty=b/"empty";empty.mkdir();config.mkdir(parents=True)
 fake.write_text('#!/bin/sh\ncat "$MONITORS"\n');fake.chmod(0o755)
 src=[{"name":"eDP-1","description":"PRIVATE SERIAL 123","width":1920,"height":1080,"refreshRate":60,"x":0,"y":0,"scale":1,"transform":0},{"name":"DP-9","description":"PRIVATE DEVICE ABC","width":2560,"height":1440,"refreshRate":60,"x":1920,"y":0,"scale":1,"transform":0}];fixture.write_text(json.dumps(src))
 (config/"operating-profiles.json").write_text(json.dumps({"travel":{"power_profile":"power-saver","bar_size":24,"audio_target":"internal","wallpaper":"eva.png","display_layout":"internal"}}))
 (config/"topologies.json").write_text(json.dumps({"schema_version":1,"enabled":False,"debounce_ms":1500,"profiles":{"private-dock":{"fingerprint":"0123456789abcdef","kind":"dock","monitors":src,"windows":[{"address":"0xSECRET"}],"workspaces":[{"workspace":2,"monitor":"DP-9"}],"focused_workspace":2,"surfaces":{"bar_position":"top","presentation_workspace":5}}}}))
 env={**os.environ,"HOME":str(home),"XDG_CONFIG_HOME":str(b/"config"),"XDG_STATE_HOME":str(state),"EVA_MACHINE_PROFILE_HYPRCTL":str(fake),"EVA_MACHINE_PROFILE_COMMAND_PATH":str(empty),"PATH":str(empty)+":/usr/bin","MONITORS":str(fixture)}
 def run(*a,ok=True,extra=None):
  p=subprocess.run([str(CMD),*map(str,a)],env=env|({} if extra is None else extra),text=True,capture_output=True)
  if ok and p.returncode:raise AssertionError(p.stderr)
  return p
 out=b/"bundle.json";run("export",out);payload=json.loads(out.read_text());blob=out.read_text();assert stat.S_IMODE(out.stat().st_mode)==0o600 and payload["schema_version"]==1
 for private in ("PRIVATE SERIAL","PRIVATE DEVICE","0xSECRET","DP-9","eDP-1","0123456789abcdef"):assert private not in blob
 assert payload["redaction_report"]["removed"]["device_ids"]==2 and payload["topology_templates"]["private-dock"]["monitors"][1]["role"]=="external-1"
 destination=[{**src[0],"name":"eDP-2","description":"Destination Internal"},{**src[1],"name":"HDMI-A-1","description":"Destination External"}];fixture.write_text(json.dumps(destination));before_ops=(config/"operating-profiles.json").read_bytes();before_top=(config/"topologies.json").read_bytes();plan=json.loads(run("import",out).stdout);assert plan["read_only"] and (config/"operating-profiles.json").read_bytes()==before_ops
 assert {x["field"] for x in plan["capability_remapping"]["changes"]}=={"power_profile","audio_target"}
 assert plan["capability_remapping"]["output_mapping"]=={"internal":"eDP-2","external-1":"HDMI-A-1"}
 assert run("import",out,"--confirm","wrong",ok=False).returncode!=0
 result=json.loads(run("import",out,"--confirm",plan["plan_id"]).stdout);mapped=json.loads((config/"topologies.json").read_text())["profiles"]["private-dock"];assert mapped["monitors"][1]["name"]=="HDMI-A-1" and mapped["workspaces"][0]["monitor"]=="HDMI-A-1"
 run("rollback",result["transaction"]);assert (config/"operating-profiles.json").read_bytes()==before_ops and (config/"topologies.json").read_bytes()==before_top
 plan=json.loads(run("import",out).stdout);failed=run("import",out,"--confirm",plan["plan_id"],ok=False,extra={"EVANGELION_FORCE_MACHINE_PROFILE_FAILURE":"1"});assert failed.returncode!=0 and (config/"topologies.json").read_bytes()==before_top
 hostile=json.loads(out.read_text());hostile["topology_templates"]["private-dock"]["monitors"][0]["role"]='internal\"; exec evil';bad=b/"bad.json";bad.write_text(json.dumps(hostile));assert run("import",bad,ok=False).returncode!=0
 hostile=json.loads(out.read_text());hostile["token"]="secret";bad.write_text(json.dumps(hostile));assert run("import",bad,ok=False).returncode!=0
 hostile=json.loads(out.read_text());hostile["topology_templates"]["private-dock"]["surfaces"]["host"]="/private/path";bad.write_text(json.dumps(hostile));assert run("import",bad,ok=False).returncode!=0
 assert run("rollback","../../escape",ok=False).returncode!=0
 fixture.write_text(json.dumps(destination[:1]));short=json.loads(run("import",out).stdout);assert short["capability_remapping"]["topologies"][0]["status"]=="skipped"
print("PASS  versioned machine profiles redaction semantic remapping dry-run conflicts transaction rollback and hostile input")
