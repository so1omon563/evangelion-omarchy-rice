#!/usr/bin/env python3
import base64, json, os, subprocess, tempfile
from pathlib import Path

root=Path(__file__).resolve().parents[1]
command=root/"bin/magi-bar-refresh"
affinity=(root/"bin/magi-affinity").read_text()
menu=(root/"omarchy/extensions/omarchy-menu.jsonc").read_text()

with tempfile.TemporaryDirectory() as raw:
  tmp=Path(raw); home=tmp/"home"; state=tmp/"state"; runtime=tmp/"run"; stubs=tmp/"bin"
  theme=state/"omarchy/current/theme"
  for directory in (home,state,runtime,stubs,theme): directory.mkdir(parents=True,exist_ok=True)
  colors='accent = "#9CF23A"\nforeground = "#E8E1EF"\n'
  shell='[bar]\ntext = "#B79ACB"\n'
  (theme/"colors.toml").write_text(colors); (theme/"shell.toml").write_text(shell)
  log=tmp/"ipc.json"
  stub=stubs/"omarchy-shell"
  stub.write_text(f'''#!/usr/bin/env python3
import json,os,sys
if os.environ.get("FAIL_SHELL") == "1": raise SystemExit(1)
json.dump(sys.argv[1:],open({str(log)!r},"w"))
print("ok")
'''); stub.chmod(0o755)
  env=os.environ|{"HOME":str(home),"XDG_STATE_HOME":str(state),"XDG_RUNTIME_DIR":str(runtime),"PATH":str(stubs)+":"+os.environ["PATH"]}

  first=subprocess.run([str(command),"--source","test"],env=env,text=True,capture_output=True)
  assert first.returncode==0,first.stderr
  args=json.loads(log.read_text()); assert args[:2]==["shell","applyTheme"] and len(args)==4,args
  assert base64.b64decode(args[2]).decode()==colors
  assert base64.b64decode(args[3]).decode()==shell
  status=json.loads(subprocess.run([str(command),"status"],env=env,check=True,text=True,capture_output=True).stdout)
  assert status["result"]=="success" and status["source"]=="test",status
  second=subprocess.run([str(command),"--source","test"],env=env,text=True,capture_output=True)
  assert second.returncode==0

  failed=subprocess.run([str(command),"--source","test"],env=env|{"FAIL_SHELL":"1"},text=True,capture_output=True)
  assert failed.returncode!=0 and "omarchy restart shell" in failed.stderr
  status=json.loads(subprocess.run([str(command),"status"],env=env,check=True,text=True,capture_output=True).stdout)
  assert status["result"]=="failed" and status["reason"]=="shell-ipc-unavailable",status

  (theme/"shell.toml").unlink()
  missing=subprocess.run([str(command)],env=env,text=True,capture_output=True)
  assert missing.returncode!=0 and "shell.toml" in missing.stderr

contracts={
  "supported_ipc":'shell applyTheme "$colors_payload" "$shell_payload"' in command.read_text(),
  "bounded_ipc":'OMARCHY_SHELL_IPC_TIMEOUT=2s timeout 3' in command.read_text(),
  "serialized":'flock -w 2' in command.read_text(),
  "automatic_after_commit":'magi-bar-refresh --quiet --source affinity' in affinity and affinity.index('mv -f "$tmp/active" "$active_file"') < affinity.index('magi-bar-refresh --quiet --source affinity'),
  "failure_is_actionable":'Run magi-bar-refresh; if needed, run omarchy restart shell.' in affinity,
  "no_automatic_restart":'omarchy restart shell' not in command.read_text().split("Recovery:")[0],
  "menu_recovery":'"magi.affinity.refresh-bar"' in menu and 'magi-bar-refresh --notify' in menu,
}
failed=[name for name,value in contracts.items() if not value]
if failed: raise AssertionError(", ".join(failed))
print("bar refresh contracts passed")
