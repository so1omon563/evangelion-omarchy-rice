#!/usr/bin/env python3
import json,os,stat,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];CMD=ROOT/"bin/magi-onboard"
with tempfile.TemporaryDirectory() as raw:
 b=Path(raw);home=b/"home";config=b/"config";state=b/"state";env={**os.environ,"HOME":str(home),"XDG_CONFIG_HOME":str(config),"XDG_STATE_HOME":str(state),"EVANGELION_SKIP_ACTIVATE":"1"}
 def run(*a,ok=True):return subprocess.run([str(CMD),*map(str,a)],env=env,text=True,capture_output=True,check=ok)
 assert json.loads(run("status").stdout)["state"]=="new";run("skip");assert json.loads(run("status").stdout)["state"]=="skipped";run("reopen");assert json.loads(run("status").stdout)["state"]=="new"
 src=config/"omarchy/evangelion.json";src.parent.mkdir(parents=True);src.write_text(json.dumps({"project_dir":"/private/work","editor":["/bin/private"],"ambient":{"location":{"latitude":1}},"deployment":{"browser_url":"https://private"},"terminal":"auto"}))
 out=b/"portable.json";run("export",out);payload=json.loads(out.read_text());text=out.read_text();assert "/private" not in text and "latitude" not in text and "https://private" not in text and payload["privacy"]=={"paths":False,"devices":False,"secrets":False,"location":False};assert stat.S_IMODE(out.stat().st_mode)==0o600
 payload["components"]["core"]["terminal"]="foot";out.write_text(json.dumps(payload));before=src.read_bytes();plan=json.loads(run("import",out).stdout);assert src.read_bytes()==before and plan["read_only"]
 assert run("import",out,"--confirm","wrong",ok=False).returncode!=0 and src.read_bytes()==before
 result=json.loads(run("import",out,"--confirm",plan["plan_id"]).stdout);assert json.loads(src.read_text())["terminal"]=="foot";run("rollback",result["transaction"]);assert src.read_bytes()==before
 hostile=b/"bad.json";payload["components"]["core"]["token"]="x";hostile.write_text(json.dumps(payload));assert run("import",hostile,ok=False).returncode!=0
 payload["components"]["core"].pop("token");payload["components"]["core"]["project_dir"]="/home/private";hostile.write_text(json.dumps(payload));assert run("import",hostile,ok=False).returncode!=0
 payload["components"]["core"]["project_dir"]="";payload["components"]["core"]["unknown"]="x";hostile.write_text(json.dumps(payload));assert run("import",hostile,ok=False).returncode!=0
 payload["components"]["core"].pop("unknown");hostile.write_text(json.dumps(payload));plan=json.loads(run("import",hostile).stdout);failed={**env,"EVANGELION_FORCE_ONBOARDING_FAILURE":"1"};result=subprocess.run([str(CMD),"import",str(hostile),"--confirm",plan["plan_id"]],env=failed,text=True,capture_output=True);assert result.returncode!=0 and src.read_bytes()==before
 assert run("rollback","../../bad",ok=False).returncode!=0
print("PASS  skippable onboarding sanitized export schema conflict preview transactional import rollback")
