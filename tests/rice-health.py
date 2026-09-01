#!/usr/bin/env python3
import json, os, stat, subprocess, tempfile, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-rice-health"
with tempfile.TemporaryDirectory() as directory:
    base=Path(directory); home=base/"home"; data=base/"data"; plugins=home/".config/omarchy/plugins"; state=base/"state"
    plugin=plugins/"evangelion.example"; plugin.mkdir(parents=True); (plugin/"Widget.qml").write_text("import QtQuick\nItem{}\n")
    (plugin/"manifest.json").write_text(json.dumps({"id":"evangelion.example","entryPoints":{"barWidget":"Widget.qml"}}))
    shell=home/".config/omarchy/shell.json"; shell.parent.mkdir(parents=True,exist_ok=True)
    shell.write_text(json.dumps({"version":1,"bar":{"layout":{"left":[{"id":"evangelion.example"}]}},"plugins":[]}))
    installed=home/".local/state/evangelion-rice/migrations/installed-version"; installed.parent.mkdir(parents=True); installed.write_text("1.5.0\n")
    cache=home/".local/state/evangelion-rice/health-updates.json"; cache.parent.mkdir(parents=True,exist_ok=True); cache.write_text('{"count":0,"checked_at":1}\n')
    old=time.time()-4000; os.utime(cache,(old,old))
    deps=data/"dependencies.tsv"; deps.parent.mkdir(parents=True); deps.write_text("required\tbase\tpython3\tpython\tRuntime\n")
    config=data/"rice-health.json"; config.write_text(json.dumps({"schema_version":1,"suite_version":"1.5.0","required_services":[],"owned_port":{"number":65531,"service":"none.service"},"stale_seconds":{"health_cache":1800},"allowlisted_fixes":["quarantine-stale-health-cache"]}))
    env={**os.environ,"EVA_RICE_HEALTH_HOME":str(home),"EVA_RICE_HEALTH_ROOT":str(data),"EVA_RICE_HEALTH_CONFIG":str(config),"EVA_RICE_HEALTH_DEPENDENCIES":str(deps),"EVA_RICE_HEALTH_STATE":str(state),"EVA_RICE_HEALTH_SHELL":str(shell),"EVA_RICE_HEALTH_PLUGINS":str(plugins),"EVA_RICE_HEALTH_CACHE":str(cache),"EVA_RICE_HEALTH_INSTALLED":str(installed)}
    def run(*args,check=True): return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=check)
    report=json.loads(run("diagnose","--json").stdout)
    assert report["read_only"] is True and report["status"]=="attention" and report["fixes"]==["quarantine-stale-health-cache"]
    assert {row["category"] for row in report["findings"]}=={"version","dependencies","services","widgets","ownership","ports","schemas","cache"}
    assert all(set(row)>={"id","category","severity","status","summary","evidence","reason"} for row in report["findings"])
    deps.rename(data/"dependencies.saved"); unavailable=json.loads(run("diagnose","--json").stdout)
    assert next(row for row in unavailable["findings"] if row["id"]=="suite.dependencies")["status"]=="unavailable"
    (data/"dependencies.saved").rename(deps)
    plan=json.loads(run("preview","quarantine-stale-health-cache","--json").stdout); assert cache.exists() and plan["requires_confirmation"] is True
    denied=run("apply","quarantine-stale-health-cache","--confirm","wrong",check=False); assert denied.returncode!=0 and cache.exists()
    applied=json.loads(run("apply","quarantine-stale-health-cache","--confirm",plan["plan_id"]).stdout); assert not cache.exists()
    transaction=state/"transactions"/applied["id"]; assert stat.S_IMODE(transaction.stat().st_mode)==0o700
    assert stat.S_IMODE((transaction/"manifest.json").stat().st_mode)==0o600
    rolled=json.loads(run("rollback",applied["id"]).stdout); assert rolled["status"]=="rolled-back" and cache.read_text()=='{"count":0,"checked_at":1}\n'
    rejected=run("preview","reset-everything",check=False); assert rejected.returncode!=0
    traversal=run("rollback","../../outside",check=False); assert traversal.returncode!=0
    shell.write_text("not json\n"); broken=json.loads(run("diagnose","--json",check=False).stdout)
    assert broken["status"]=="critical" and any(row["id"]=="suite.schemas" and row["status"]=="failed" for row in broken["findings"])
source=(ROOT/"omarchy/plugins/evangelion.health/BarWidget.qml").read_text(); docs=(ROOT/"RICE_HEALTH.md").read_text()
for phrase in ('command:["magi-rice-health","diagnose","--json"]','root.riceStatus.findings','health.preview_remediation','root.remediation()'): assert phrase in source
for phrase in ("always read-only","allowlisted","plan_id","byte-for-byte","rollback stops"): assert phrase in docs
print("PASS  read-only diagnosis evidence CLI GUI parity allowlist confirmation and exact rollback")
