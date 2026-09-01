#!/usr/bin/env python3
import json, os, stat, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-snapshot"
with tempfile.TemporaryDirectory() as raw:
    base=Path(raw); home=base/"home"; config=home/".config"; state=home/".local/state"; store=state/"evangelion-rice/snapshots"; spec=base/"spec.json"
    spec.write_text(json.dumps({"schema_version":1,"retention":2,"components":{"layouts":[{"root":"config","path":"omarchy/shell.json"}],"profiles":[{"root":"config","path":"omarchy/profile.json"}],"affinity":[{"root":"state","path":"evangelion-rice/affinity-mode"}],"settings":[{"root":"config","path":"omarchy/settings.json"}]}}))
    files={"layouts":config/"omarchy/shell.json","profiles":config/"omarchy/profile.json","affinity":state/"evangelion-rice/affinity-mode","settings":config/"omarchy/settings.json"}
    for name,path in files.items(): path.parent.mkdir(parents=True,exist_ok=True); path.write_text(json.dumps({"component":name})+"\n")
    env={**os.environ,"EVA_SNAPSHOT_HOME":str(home),"XDG_CONFIG_HOME":str(config),"XDG_STATE_HOME":str(state),"EVA_SNAPSHOT_SPEC":str(spec),"EVA_SNAPSHOT_STORE":str(store),"EVA_SNAPSHOT_SKIP_ACTIVATE":"1"}
    def run(*args,check=True): return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=check)
    created=json.loads(run("create","baseline","--note","Before display tuning").stdout); assert created["files"]==4 and created["pruned"]==[]
    manifest=json.loads(run("show","baseline").stdout); assert manifest["note"]=="Before display tuning" and set(manifest["components"])==set(files)
    assert stat.S_IMODE((store/"baseline").stat().st_mode)==0o700 and stat.S_IMODE((store/"baseline/manifest.json").stat().st_mode)==0o600
    original=files["layouts"].read_bytes(); files["layouts"].write_text('{"changed":true}\n'); files["settings"].unlink()
    preview=json.loads(run("diff","baseline","--components","layouts,settings").stdout); assert preview["changed"]==2
    denied=run("restore","baseline","--components","layouts,settings","--confirm","bad",check=False); assert denied.returncode!=0 and b"changed" in files["layouts"].read_bytes()
    restored=json.loads(run("restore","baseline","--components","layouts,settings","--confirm",preview["plan_id"]).stdout); assert files["layouts"].read_bytes()==original and files["settings"].exists()
    files["layouts"].write_text('{"after":true}\n'); rolled=json.loads(run("rollback",restored["id"]).stdout); assert rolled["status"]=="rolled-back" and b"changed" in files["layouts"].read_bytes() and not files["settings"].exists()
    assert run("rollback","../../escape",check=False).returncode!=0
    payload=store/"baseline/payload/config/omarchy/shell.json"; payload.write_text("corrupt\n"); assert run("show","baseline",check=False).returncode!=0
    assert run("create","Has Spaces",check=False).returncode!=0 and run("create","secret-note","--note","token=abc",check=False).returncode!=0
    payload.write_bytes(original)
    files["settings"].write_text('{"api_token":"forbidden"}\n'); assert run("create","unsafe",check=False).returncode!=0
    files["settings"].write_text('{broken\n'); assert run("create","malformed",check=False).returncode!=0
    files["settings"].write_text('{"safe":true}\n')
    run("create","second"); third=json.loads(run("create","third").stdout); assert third["pruned"]==["baseline"] and not (store/"baseline").exists()
    listed=json.loads(run("list").stdout); assert [x["name"] for x in listed["snapshots"]]==["second","third"] and listed["retention"]==2
print("PASS  exact private named snapshots selective diff restore retention corruption secrets and rollback")
