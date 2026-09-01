#!/usr/bin/env python3
"""Acceptance coverage for the v1.5 localization and resilient-layout foundation."""

import json, os, subprocess, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-i18n"
catalog=json.loads((ROOT/"omarchy/i18n/en-US.json").read_text()); strings=catalog["strings"]
assert catalog["schema_version"]==1 and catalog["locale"]=="en-US" and catalog["direction"]=="ltr"
assert len(strings)>=50 and len(strings)==len(set(strings)) and all(strings.values())
assert catalog["protected_terms"]==["NERV","MAGI","EVA","Tokyo-3","A.T. Field"]

with tempfile.TemporaryDirectory() as directory:
    env={**os.environ,"HOME":directory,"XDG_STATE_HOME":str(Path(directory)/"state")}
    def run(*args): return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=True).stdout.strip()
    assert run("status")=="en-US" and run("get","context.recommended","count=2")=="Recommended actions // 2"
    run("set","qps-ploc"); expanded=json.loads(run("catalog"))
    assert expanded["pseudo"] and expanded["direction"]=="ltr"
    assert len(expanded["strings"]["demo.banner"])>len(strings["demo.banner"])*1.2
    assert "{count}" in expanded["strings"]["context.recommended"]
    for term in catalog["protected_terms"]:
        for key,value in strings.items():
            if term in value: assert term in expanded["strings"][key]
    run("set","ar-XB"); rtl=json.loads(run("catalog"))
    assert rtl["direction"]=="rtl" and all(value.startswith("\u202e") for value in rtl["strings"].values())
    run("reset"); assert run("status")=="en-US"
    state=Path(env["XDG_STATE_HOME"])/"evangelion-rice/i18n/state.json"
    assert state.stat().st_mode&0o777==0o600 and set(json.loads(state.read_text()))=={"schema_version","locale"}

demo=(ROOT/"omarchy/plugins/evangelion.demo/Service.qml").read_text(); context=(ROOT/"omarchy/plugins/evangelion.context/BarWidget.qml").read_text(); component=(ROOT/"omarchy/plugins/evangelion.localization/I18n.qml").read_text()
for source in (demo,context):
    assert "LayoutMirroring.enabled:i18n.rtl" in source and "LayoutMirroring.childrenInherit:true" in source
assert 'i18n.tr("demo.banner")' in demo and 'i18n.tr("context.inspector")' in context
assert "ElideRight" in demo and "ElideRight" in context and "wrapMode:Text.Wrap" in context
assert 'command:["magi-i18n","catalog"]' in component and "strings[key]===undefined?key" in component
for stale in ("DEMONSTRATION MODE  //  FICTIONAL DATA", "MAGI // CONTEXT INSPECTOR", "NO ACTION RECOMMENDED"):
    assert stale not in demo+context

docs=(ROOT/"LOCALIZATION.md").read_text()
for phrase in ("only production language","pseudo-locales","LayoutMirroring","ISO-8601 UTC","named placeholder","protected"):
    assert phrase.lower() in docs.lower()
print("PASS  catalog fallback, protected terms, expansion, RTL, formatting, and resilient layouts")
