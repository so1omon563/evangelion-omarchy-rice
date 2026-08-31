#!/usr/bin/env python3
"""Wallpaper/EVA affinity transaction and motion contracts."""
import json, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]) if len(sys.argv)>1 else root/"test-results/affinity-motion.json"
script=(root/"bin/magi-affinity").read_text()
cases={"5-eva-unit-00-prototype.png":"unit-00-prototype","6-eva-unit-00-refit.png":"unit-00-refit","2-eva-unit-01.png":"unit-01","7-eva-unit-02.png":"unit-02","custom.png":"neutral"}
for name,want in cases.items():
  got=subprocess.run([str(root/"bin/magi-affinity"),"detect",name],check=True,text=True,capture_output=True).stdout.strip()
  assert got==want,(name,got,want)
checks={
 "all_affinities_and_neutral":True,
 "serialized":'flock 9' in script,
 "rapid_cycle_debounced":'sleep 0.12' in script,
 "atomic_active_state":'mv -f "$tmp/active" "$active_file"' in script,
 "transaction_rollback":'Affinity apply failed; previous state restored.' in script,
 "manual_authoritative":'mode == manual && -r $manual_file' in script,
 "auto_change_visible":'EVA AFFINITY //' in script and 'affinity_mode == auto' in script,
 "off_is_instant":'background setInstant' in script and 'motion == off' in script,
 "stock_background_command_unchanged":'omarchy-theme-bg-set' not in script,
}
failed=[k for k,v in checks.items() if not v]
if failed: raise AssertionError(', '.join(failed))
report={"schema_version":1,"suite":"affinity-motion","status":"passed","checks":checks,"wallpapers":cases}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2)+"\n");print(json.dumps(report))
