#!/usr/bin/env python3
import json, os, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; COMMAND=ROOT/"bin/magi-performance-budget"
budgets=json.loads((ROOT/"omarchy/performance-budgets.json").read_text()); inventory=json.loads((ROOT/"omarchy/performance-inventory.json").read_text())
evidence=json.loads((ROOT/"evidence/performance-v1.5.json").read_text())
assert budgets["schema_version"]==inventory["schema_version"]==1
assert budgets["budgets"]=={"startup_ready_ms":3000,"idle_cpu_percent":12,"idle_rss_mib":650,"command_p95_ms":350,"minimum_background_poll_ms":5000,"maximum_concurrent_probes":1}
assert set(budgets["cache_max_age_seconds"])=={"context","health","mission","motion"}
assert evidence["ticket"]=="SO1-409" and evidence["before"]["measurement_available"] is False
assert evidence["after"]["idle_cpu_percent"]<budgets["budgets"]["idle_cpu_percent"]
assert evidence["after"]["idle_rss_mib"]<budgets["budgets"]["idle_rss_mib"]
with tempfile.TemporaryDirectory() as directory:
    base=Path(directory); report=base/"report.json"; env={**os.environ,"EVA_BUDGET_REPORT":str(report)}
    def run(*args,check=True): return subprocess.run([str(COMMAND),*args],env=env,text=True,capture_output=True,check=check)
    assert json.loads(run("static").stdout)["status"]=="passed"
    good=base/"good.json"; good.write_text(json.dumps({"startup_ready_ms":1200,"idle_cpu_percent":.4,"idle_rss_mib":180,"command_p95_ms":40,"minimum_background_poll_ms":5000,"maximum_concurrent_probes":1,"cache_age_seconds":{"context":10,"health":10,"mission":10,"motion":10}}))
    assert json.loads(run("check",str(good)).stdout)["status"]=="passed"
    bad=base/"bad.json"; bad.write_text(json.dumps({"startup_ready_ms":4000,"idle_cpu_percent":13,"idle_rss_mib":700,"command_p95_ms":400,"minimum_background_poll_ms":1000,"maximum_concurrent_probes":2,"cache_age_seconds":{"context":301,"health":901,"mission":3601,"motion":86401}}))
    failed=run("check",str(bad),check=False); value=json.loads(failed.stdout)
    assert failed.returncode==1 and value["status"]=="failed" and len(value["failures"])==10
    partial=json.loads(run("check").stdout); assert partial["status"]=="partial" and len(partial["unavailable"])==10
    serialized=report.read_text().lower()
    for prohibited in ("pid","hostname","username","ssid","window_title","command_line","stdout","stderr"): assert prohibited not in serialized
performance=(ROOT/"bin/magi-performance").read_text(); overlay=(ROOT/"omarchy/plugins/evangelion.performance/Service.qml").read_text(); docs=(ROOT/"PERFORMANCE.md").read_text()
assert "BUDGET_REPORT" in performance and '"budgets":budget' in performance and "BUDGET GATE" in overlay
for phrase in ("disabled by default","one probe per cycle","event-driven","partial","code review"): assert phrase in docs
print("PASS  startup idle polling cache overlap privacy and safety-exception budgets")
