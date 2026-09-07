#!/usr/bin/env python3
"""Registry, fuzzy ranking, dynamic entries, safety, and accessible UI tests."""
import json,os,subprocess,tempfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];CLI=ROOT/"bin/magi-command-palette"
registry=json.loads((ROOT/"omarchy/commands.json").read_text());assert registry["schema_version"]==1
assert len(registry["commands"])>=25 and {row["danger"] for row in registry["commands"]}=={"safe","caution","confirm","destructive"}
assert len({row["id"] for row in registry["commands"]})==len(registry["commands"])
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);data=base/"data";config=base/".config/omarchy";state=base/"state";bindir=base/"bin";data.joinpath("omarchy").mkdir(parents=True);config.mkdir(parents=True);bindir.mkdir()
 (data/"omarchy/commands.json").write_text(json.dumps(registry));(data/"omarchy/settings-schema.json").write_text((ROOT/"omarchy/settings-schema.json").read_text());(config/"workspaces.json").write_text(json.dumps({"schema_version":1,"workspaces":[{"id":7,"label":"SEVENTH HEAVEN"}]}))
 log=base/"log";stub=bindir/"runner";stub.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$PALETTE_LOG"\n');stub.chmod(0o755)
 fixture={"schema_version":1,"commands":[{"id":"safe.run","label":"Run safe fixture","category":"Test","description":"safe","aliases":["fixture"],"danger":"safe","action":[str(stub),"safe"]},{"id":"danger.run","label":"Run dangerous fixture","category":"Test","description":"danger","aliases":["fixture"],"danger":"destructive","action":[str(stub),"danger"]}]};fixture_path=base/"fixture.json";fixture_path.write_text(json.dumps(fixture))
 env={**os.environ,"HOME":str(base),"XDG_CONFIG_HOME":str(base/"config"),"EVA_PALETTE_DATA":str(data),"EVA_PALETTE_STATE":str(state),"PALETTE_LOG":str(log)}
 def run(*args,ok=True,extra=None):
  result=subprocess.run([str(CLI),*args],env={**env,**(extra or {})},text=True,capture_output=True)
  if ok:result.check_returncode()
  return result
 first=json.loads(run("search","sys helth","--json").stdout);second=json.loads(run("search","sys helth","--json").stdout);assert first==second and first["results"][0]["id"]=="telemetry.health"
 all_rows=json.loads(run("registry").stdout)["commands"];assert any(row["id"]=="setting.visual.density" for row in all_rows) and any(row["id"]=="workspace.7" for row in all_rows);assert all("action" not in row for row in all_rows)
 fixture_env={"EVA_PALETTE_REGISTRY":str(fixture_path)};run("execute","danger.run",ok=False,extra=fixture_env);plan=json.loads(run("prepare","danger.run",extra=fixture_env).stdout);assert plan["requires_confirmation"] and plan["danger"]=="destructive";run("execute","danger.run","--confirm",plan["token"],extra=fixture_env)
 run("execute","safe.run",extra=fixture_env)
 for _ in range(20):
  if log.exists() and {"safe","danger"}<=set(log.read_text().splitlines()):break
  time.sleep(.02)
 assert {"safe","danger"}<=set(log.read_text().splitlines()) and not (state/"confirmation.json").exists()
qml=(ROOT/"omarchy/plugins/evangelion.command-palette/Service.qml").read_text();bindings=(ROOT/"hypr/bindings.lua").read_text();shell=json.loads((ROOT/"omarchy/shell.json").read_text())
for phrase in ('Accessible.role: Accessible.EditableText','Accessible.name: "Search MAGI commands"','Qt.Key_Down','Qt.Key_Up','Qt.Key_Return','requires_confirmation','ENTER AGAIN WITHIN 60 SECONDS','String(modelData.category)','String(modelData.danger)'):assert phrase in qml,phrase
assert 'SUPER + CTRL + ALT + M' in bindings and any(row["id"]=="evangelion.command-palette" for row in shell["plugins"])
print("PASS  global deterministic fuzzy command palette registry dynamic entries confirmation and accessibility")
