#!/usr/bin/env python3
"""Release-channel selection, evidence, stale state, exact preview, apply, and undo."""
import json
import os
import stat
import subprocess
import tempfile
import time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1];COMMAND=ROOT/"bin/magi-suite-update"
def run(env,*args,check=True):return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=check)
def executable(path,text):path.write_text(text);path.chmod(path.stat().st_mode|stat.S_IXUSR)

with tempfile.TemporaryDirectory(prefix="evangelion-suite-update-") as raw:
    base=Path(raw);source=base/"source";source.mkdir();(source/"VERSION").write_text("1.6.0\n")
    executable(source/"install.sh",'''#!/usr/bin/env bash
set -e
if [[ $1 == --dry-run ]]; then echo "EVANGELION INSTALL PLAN // fixture"; echo "REPLACE shell fixture"; echo "DRY RUN COMPLETE // no target files changed"; exit; fi
snapshot="$XDG_STATE_HOME/fixture-snapshot"; mkdir -p "$snapshot"; echo applied >"$snapshot/marker"; echo "INSTALL COMPLETE // rollback snapshot: $snapshot"
''')
    executable(source/"rollback.sh",'''#!/usr/bin/env bash
set -e
[[ -f $1/marker ]]; rm "$1/marker"; echo "ROLLBACK COMPLETE // $1"
''')
    index=base/"index.json";index.write_text(json.dumps({"channels":{
      "stable":{"version":"1.6.0","ref":"v1.6.0","commit":"a"*40,"evidence":{"kind":"tag","tag_object":"annotated","signature":"verified","release_gate":True}},
      "preview":{"version":"1.7.0-rc.1","ref":"v1.7.0-rc.1","commit":"b"*40,"evidence":{"kind":"tag","tag_object":"annotated","signature":"verified","release_gate":True}},
      "development":{"version":"development","ref":"main","commit":"c"*40,"evidence":{"kind":"branch","signature":"not-applicable","release_gate":False}}
    }}))
    home=base/"home";config=base/"config";state=base/"state";installed=home/".local/share/evangelion-rice";installed.mkdir(parents=True);(installed/".suite-version").write_text("1.5.0\n")
    env={**os.environ,"HOME":str(home),"XDG_CONFIG_HOME":str(config),"XDG_STATE_HOME":str(state),"EVANGELION_UPDATE_INDEX":str(index),"EVANGELION_UPDATE_SOURCE":str(source),"EVANGELION_SKIP_ACTIVATE":"1"}

    assert run(env,"channel").stdout.strip()=="stable"
    checked=json.loads(run(env,"check","--json").stdout)
    assert checked["channel"]=="stable" and checked["evidence"]["signature"]=="verified" and checked["update_available"] is True
    preview=json.loads(run(env,"preview","--json").stdout);plan=preview["plan_id"]
    assert preview["commit"]=="a"*40 and "REPLACE shell fixture" in preview["exact_plan"]
    assert run(env,"apply","--plan","wrong","--yes",check=False).returncode!=0
    assert run(env,"apply","--plan",plan,check=False).returncode!=0
    applied=run(env,"apply","--plan",plan,"--yes");assert "SUITE UPDATE COMPLETE" in applied.stdout
    active=json.loads((state/"evangelion-rice/suite-update/active.json").read_text());snapshot=Path(active["rollback_snapshot"]);assert (snapshot/"marker").exists()
    assert run(env,"undo",check=False).returncode!=0
    run(env,"undo","--yes");assert not (snapshot/"marker").exists()

    rejected=run(env,"channel","preview",check=False);assert rejected.returncode!=0 and "--accept-risk" in rejected.stderr
    assert "no update was applied" in run(env,"channel","preview","--accept-risk").stdout
    assert run(env,"channel").stdout.strip()=="preview"
    stale=run(env,"preview",check=False);assert stale.returncode!=0 and "selected channel" in stale.stderr
    preview_check=json.loads(run(env,"check","--json").stdout);assert preview_check["channel"]=="preview"
    run(env,"channel","development","--accept-risk")
    development=json.loads(run(env,"check","--json").stdout)
    assert development["channel"]=="development" and development["ref"]=="main" and development["evidence"]["kind"]=="branch"
    run(env,"channel","preview","--accept-risk");run(env,"check","--json")
    index.unlink();cached=json.loads(run(env,"check","--json").stdout)
    assert cached["source"]=="cache" and "offline_reason" in cached and cached["channel"]=="preview"
    cfg=config/"omarchy/evangelion-update.json";value=json.loads(cfg.read_text());value["stale_after_seconds"]=0;cfg.write_text(json.dumps(value));time.sleep(1)
    stale=run(env,"preview",check=False);assert stale.returncode!=0 and "stale" in stale.stderr.lower()

    # Downgrades add a second acknowledgment beyond the exact preview ID.
    value=json.loads(cfg.read_text());value["selected_channel"]="stable";value["stale_after_seconds"]=86400;cfg.write_text(json.dumps(value))
    index.write_text(json.dumps({"channels":{"stable":{"version":"1.4.1","ref":"v1.4.1","commit":"d"*40,"evidence":{"kind":"tag","tag_object":"annotated","signature":"unsigned-or-untrusted","release_gate":True}}}}))
    checked=json.loads(run(env,"check","--json").stdout);assert checked["evidence"]["signature"]=="unsigned-or-untrusted"
    down=json.loads(run(env,"preview","--json").stdout);assert down["direction"]=="downgrade"
    refused=run(env,"apply","--plan",down["plan_id"],"--yes",check=False);assert refused.returncode!=0 and "--allow-downgrade" in refused.stderr

print("PASS  explicit release channels evidence offline cache exact preview transaction and undo")
