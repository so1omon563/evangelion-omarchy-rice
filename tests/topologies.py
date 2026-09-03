#!/usr/bin/env python3
import json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);home=base/"home";fake=base/"hyprctl";fixture=base/"fixture.json";log=base/"calls.log";config=home/".config/omarchy/topologies.json";state=home/".local/state/evangelion-rice/topology";shell=home/".config/omarchy/shell.json";core=home/".config/omarchy/evangelion.json"
 fake.write_text('#!/usr/bin/env bash\nset -eu\nif [[ ${1:-} == monitors && ${2:-} == -j ]]; then jq -c .monitors "$FIXTURE"; elif [[ ${1:-} == clients && ${2:-} == -j ]]; then jq -c .clients "$FIXTURE"; else printf "%s\\n" "$*" >>"$CALLS"; fi\n');fake.chmod(0o755)
 data={"monitors":[{"id":0,"name":"eDP-1","description":"Internal Panel","width":1920,"height":1080,"refreshRate":60,"x":0,"y":0,"scale":1,"transform":0,"focused":True,"activeWorkspace":{"id":1}},{"id":1,"name":"DP-1","description":"External QHD","width":2560,"height":1440,"refreshRate":60,"x":1920,"y":0,"scale":1,"transform":0,"focused":False,"activeWorkspace":{"id":2}}],"clients":[{"address":"0xabc","monitor":1,"workspace":{"id":2},"title":"PRIVATE"}]};fixture.write_text(json.dumps(data))
 shell.parent.mkdir(parents=True);shell.write_text('{"bar":{"position":"top"}}');core.write_text('{"presentation":{"workspace":5}}')
 env={**os.environ,"HOME":str(home),"EVA_TOPOLOGY_CONFIG":str(config),"EVA_TOPOLOGY_STATE":str(state),"EVA_TOPOLOGY_HYPRCTL":str(fake),"EVA_TOPOLOGY_SHELL":str(shell),"EVA_TOPOLOGY_CORE":str(core),"EVA_TOPOLOGY_NO_SYSTEMD":"1","FIXTURE":str(fixture),"CALLS":str(log)}
 def run(*a,ok=True):
  p=subprocess.run([str(ROOT/"bin/magi-topology"),*a],env=env,text=True,capture_output=True)
  if ok and p.returncode:raise AssertionError(p.stderr)
  return p
 assert json.loads(run("status").stdout)["current"]["kind"]=="dock"
 run("save","home-dock");saved=json.loads(config.read_text());assert config.stat().st_mode&0o777==0o600
 blob=json.dumps(saved);assert "PRIVATE" not in blob and "0xabc" not in blob and "serial" not in blob.lower()
 before=log.read_text() if log.exists() else "";preview=json.loads(run("preview","home-dock").stdout);after=log.read_text() if log.exists() else "";assert after==before
 assert run("apply","home-dock","--confirm","bad",ok=False).returncode!=0
 shell.write_text('{"bar":{"position":"bottom"}}');core.write_text('{"presentation":{"workspace":3}}');preview=json.loads(run("preview","home-dock").stdout)
 run("apply","home-dock","--confirm",preview["plan_id"]);calls=log.read_text();assert "hl.monitor" in calls and "moveworkspacetomonitor" in calls and all(x not in calls for x in ("kill","closewindow","exec"));assert json.loads(shell.read_text())["bar"]["position"]=="top" and json.loads(core.read_text())["presentation"]["workspace"]==5
 run("undo");assert not (state/"last-transaction.json").exists() and "address:0xabc" in log.read_text();assert json.loads(shell.read_text())["bar"]["position"]=="bottom" and json.loads(core.read_text())["presentation"]["workspace"]==3
 changed=json.loads(fixture.read_text());changed["monitors"][1]["description"]="Unknown Display";fixture.write_text(json.dumps(changed));unknown=json.loads(run("preview").stdout);assert unknown["action"]=="safe-fallback" and unknown["mutations"]==[]
 run("enable");assert json.loads(config.read_text())["enabled"] is True;run("disable")
 config.write_text('{"schema_version":99,"profiles":{}}');assert run("status",ok=False).returncode!=0
 hostile=saved;hostile["profiles"]["home-dock"]["monitors"][0]["name"]='eDP-1\" }); exec evil';config.write_text(json.dumps(hostile));assert run("preview","home-dock",ok=False).returncode!=0 and (not log.exists() or "evil" not in log.read_text())
 menu=(ROOT/"omarchy/extensions/omarchy-menu.jsonc").read_text();assert "magi.topology.enable" in menu and "magi.topology.undo" in menu
 assert "omarchy/topologies.json" in (ROOT/"omarchy/snapshot-manifest.json").read_text()
print("PASS  private topology identity preview confirmation apply undo unknown fallback and automation controls")
