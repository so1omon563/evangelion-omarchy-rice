#!/usr/bin/env python3
"""Stable report schema, explicit review, privacy, issue, and matrix contracts."""
import json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];BETA=ROOT/"beta-report.sh";ACCEPT=ROOT/"tools/accept-compatibility-report";SCHEMA=ROOT/"schemas/community-compatibility-report-v2.schema.json"
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);bundle=base/"bundle";bundle.mkdir();home=base/"home";home.mkdir();matrix=base/"matrix.json";matrix.write_text((ROOT/"compatibility/community-matrix.json").read_text())
 (bundle/"selection.json").write_text('["--preset","default"]\n');(bundle/"environment.json").write_text(json.dumps({"architecture":"x86_64","session_type":"wayland","displays":[{"width":1920,"height":1080,"scale":1.25,"transform":0}],"capabilities":{"battery":True,"thermal":True,"audio":True,"network":True,"terminal_count":2}}));(bundle/"commit").write_text("a"*40+"\n")
 for name in ("preflight","dry-run","install","validation","rollback"):(bundle/f"{name}.status").write_text("0\n")
 env={**os.environ,"HOME":str(home),"EVA_COMPATIBILITY_MATRIX":str(matrix)}
 def run(command,*args,ok=True):
  value=subprocess.run([str(command),*map(str,args)],env=env,text=True,capture_output=True)
  if ok:assert value.returncode==0,value.stderr
  return value
 run(BETA,"review",bundle);review=json.loads((bundle/"review.json").read_text());review.update(hardware_class="Generic integrated-graphics laptop",restoration_confirmed=True,privacy_reviewed=True,consent_to_publish=True);review["qualitative"]={"result":"pass-with-issues","issues":["Minor panel spacing"],"feedback":"Controls remained usable."};(bundle/"review.json").write_text(json.dumps(review))
 run(BETA,"finalize",bundle);report=json.loads((bundle/"report.json").read_text());assert report["schema_version"]==2 and report["all_passed"] is True and report["privacy"]["manual_review_completed"] is True
 run(ACCEPT,"--validate-only",bundle/"report.json")
 run(ACCEPT,bundle/"report.json","--issue","https://github.com/so1omon563/evangelion-omarchy-rice/issues/123");first=json.loads(matrix.read_text());assert len(first["observations"])==1 and "feedback" not in first["observations"][0] and first["release_gate"] is False
 run(ACCEPT,bundle/"report.json","--issue","https://github.com/so1omon563/evangelion-omarchy-rice/issues/123");assert len(json.loads(matrix.read_text())["observations"])==1
 unsafe=json.loads((bundle/"report.json").read_text());unsafe["qualitative"]["feedback"]="contact alice@example.com";(bundle/"unsafe.json").write_text(json.dumps(unsafe));assert run(ACCEPT,"--validate-only",bundle/"unsafe.json",ok=False).returncode!=0
 review["consent_to_publish"]=False;(bundle/"review.json").write_text(json.dumps(review));assert run(BETA,"finalize",bundle,ok=False).returncode!=0

schema=json.loads(SCHEMA.read_text());assert schema["properties"]["schema_version"]["const"]==2 and schema["additionalProperties"] is False
issue=(ROOT/".github/ISSUE_TEMPLATE/beta-report.yml").read_text();docs=(ROOT/"BETA_TESTING.md").read_text();triage=(ROOT/"COMMUNITY_REPORT_TRIAGE.md").read_text();source=BETA.read_text()
for token in ("review)","privacy_reviewed","consent_to_publish","open-issue)","xdg-open","environment.json"):assert token in source
for token in ("schema v2","raw logs","required_reports: 0","--validate-only"):assert token.lower() in (docs+triage).lower()
assert "consent to publishing" in issue.lower() and "report.json" in issue and "release_gate" in (ROOT/"compatibility/community-matrix.json").read_text()
print("PASS  privacy-reviewed stable community compatibility report and non-gating maintainer matrix workflow")
