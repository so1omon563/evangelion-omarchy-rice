#!/usr/bin/env python3
"""Privacy, retention, concurrency, offline, and keyboard operation contracts."""
import json,os,stat,subprocess,tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1];CLI=ROOT/"bin/magi-operations-log"
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);home=base/"home";home.mkdir();state=base/"state";config=base/"operations.json";exported=base/"export.json"
 config.write_text((ROOT/"omarchy/operations-log.json").read_text())
 env={**os.environ,"HOME":str(home),"EVA_OPERATIONS_STATE":str(state),"EVA_OPERATIONS_CONFIG":str(config)}
 def run(*args,ok=True):
  value=subprocess.run([str(CLI),*args],env=env,text=True,capture_output=True)
  if ok:assert value.returncode==0,value.stderr
  return value
 def value(*args):return json.loads(run(*args).stdout)
 first=value("record","security",f"Alert password=hunter2 alice@example.com 10.1.2.3 {home}/vault","--detail","Bearer abc123 cookie=session","--source","scanner","--action","shell.anything")
 raw_store=(state/"events.jsonl").read_text();assert all(secret not in raw_store for secret in ("hunter2","alice@example.com","10.1.2.3",str(home),"abc123","session"));assert first["action"]==""
 value("record","system","interleaved","--source","test")
 repeated=value("record","security",f"Alert password=hunter2 alice@example.com 10.1.2.3 {home}/vault","--detail","Bearer abc123 cookie=session","--source","scanner")
 assert repeated["id"]==first["id"] and repeated["count"]==2
 found=value("search","alert","--category","security","--limit","1");assert found["count"]==1 and len(found["entries"])==1 and found["offline"] is True
 assert run("record","unknown","bad",ok=False).returncode!=0
 def add(i):return run("record","workflow",f"Concurrent {i}","--source","test").returncode
 with ThreadPoolExecutor(max_workers=8) as pool:assert not any(pool.map(add,range(24)))
 lines=(state/"events.jsonl").read_text().splitlines();assert len(lines)==26 and all(isinstance(json.loads(line),dict) for line in lines)
 value("retention","50","14","65536")
 for i in range(55):value("record","media",f"Bounded {i}","--source","test")
 status_value=value("status");assert status_value["count"]==50 and len(status_value["entries"])==1 and status_value["storage_bytes"]<=65536
 result=value("export",str(exported));assert result["entries"]==50 and stat.S_IMODE(exported.stat().st_mode)==0o600 and json.loads(exported.read_text())["privacy"]=="sanitized-local-history"
 plan=value("clear-plan");assert plan["entries"]==50 and run("clear","--confirm","wrong",ok=False).returncode!=0
 cleared=value("clear","--confirm",plan["token"]);assert cleared["removed"]==50 and value("search")["count"]==0
 unavailable=value("record","system","Open health","--action","health.open");stub=base/"empty-bin";stub.mkdir();(stub/"python3").symlink_to("/usr/bin/python3");offline={**env,"PATH":str(stub)}
 invoked=subprocess.run([str(CLI),"invoke",unavailable["id"]],env=offline,text=True,capture_output=True);assert invoked.returncode==0 and json.loads(invoked.stdout)["status"]=="unavailable"

panel=(ROOT/"omarchy/plugins/evangelion.operations-log/Service.qml").read_text();bindings=(ROOT/"hypr/bindings.lua").read_text();notifications=(ROOT/"omarchy/plugins/evangelion.notifications/Service.qml").read_text();start=(ROOT/"start-page/server.py").read_text()
for contract in ("WlrKeyboardFocus.Exclusive","Accessible.name","Qt.Key_Up","Qt.Key_Down","Qt.Key_Return","Qt.Key_C","Qt.Key_E","Qt.Key_Escape","clear-plan","invoke"):assert contract in panel
assert '"SUPER + CTRL + ALT + O"' in bindings and "magi-operations-log" in bindings
assert "magi-operations-log" in notifications and "record_operation" in start and "except OSError" in start
shell=json.loads((ROOT/"omarchy/shell.json").read_text());assert any(item["id"]=="evangelion.operations-log" for item in shell["plugins"])
print("PASS  bounded privacy-sanitized concurrent operations log with keyboard clear export actions and offline behavior")
