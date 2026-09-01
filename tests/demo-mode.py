#!/usr/bin/env python3
"""Acceptance coverage for isolated deterministic full-interface demo mode."""

import json, os, struct, subprocess, tempfile, zlib
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-demo"
def png_chunk(kind,data): return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data)&0xffffffff)

with tempfile.TemporaryDirectory() as directory:
    base=Path(directory); home=base/"home"; fake=base/"bin"; fake.mkdir(parents=True)
    shell=fake/"omarchy-shell"; shell.write_text("#!/bin/sh\nexit 0\n"); shell.chmod(0o755)
    env={**os.environ,"HOME":str(home),"XDG_STATE_HOME":str(base/"state"),"PATH":f"{fake}:/usr/bin:/bin"}
    def run(*args,check=True): return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=check)
    scenarios=run("list").stdout.splitlines()
    assert {"neutral-nominal","unit-00-prototype","unit-00-refit","unit-01-sortie","unit-02-offline","thermal-constrained","battery-constrained","thermal-critical","battery-critical","manual-mobile"} == set(scenarios)
    run("scenario","thermal-critical"); first=json.loads(run("status","--json").stdout); second=json.loads(run("status","--json").stdout)
    assert first==second and first["active"] is True and first["demo"] is True
    assert first["status"]=="critical" and first["temperature_c"]==96 and first["privacy"]=={"live_data":False,"fictional":True,"metadata_safe_capture":True}
    serialized=json.dumps(first).lower()
    for prohibited in (str(home).lower(),"hostname","username","ssid","window_title","playerctl","hyprctl"): assert prohibited not in serialized
    run("next"); assert json.loads(run("status","--json").stdout)["scenario"]=="battery-critical"
    run("exit"); exited=json.loads(run("status","--json").stdout)
    assert exited["active"] is False and exited["scenario"]=="neutral-nominal"
    state_path=base/"state/evangelion-rice/demo/state.json"; state=json.loads(state_path.read_text())
    assert set(state)=={"schema_version","active","scenario"} and state_path.stat().st_mode & 0o777 == 0o600
    run("enter"); capture=base/"capture.png"
    capture.write_bytes(b"\x89PNG\r\n\x1a\n"+png_chunk(b"IHDR",struct.pack(">IIBBBBB",1,1,8,6,0,0,0))+png_chunk(b"tEXt",b"Author\x00Private")+png_chunk(b"IDAT",zlib.compress(b"\x00\x00\x00\x00\x00"))+png_chunk(b"IEND",b""))
    script=fake/"magi-capture"; script.write_text(f"#!/bin/sh\nprintf '%s\\n' '{capture}'\n"); script.chmod(0o755)
    run("capture"); scrubbed=capture.read_bytes(); assert b"tEXt" not in scrubbed and b"IHDR" in scrubbed and b"IDAT" in scrubbed

service=(ROOT/"omarchy/plugins/evangelion.demo/Service.qml").read_text(); shell=json.loads((ROOT/"omarchy/shell.json").read_text())
catalog=json.loads((ROOT/"omarchy/i18n/en-US.json").read_text())["strings"]
menu=(ROOT/"omarchy/extensions/omarchy-menu.jsonc").read_text(); docs=(ROOT/"DEMO.md").read_text()
assert any(item["id"]=="evangelion.demo" for item in shell["plugins"])
assert "Fictional data" in catalog["demo.banner"] and "Live providers disconnected" in catalog["demo.banner"]
assert 'i18n.tr("demo.banner")' in service and 'target:"magi-demo"' in service
assert '"magi.demo.capture"' in menu and "magi-demo exit" in menu
assert "does not modify affinity" in docs and "remove PNG text" in docs
print("PASS  deterministic isolated demo scenarios, reset, indicator, and metadata-safe capture")
