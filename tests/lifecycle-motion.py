#!/usr/bin/env python3
"""Contracts for mutually exclusive boot/idle/screensaver/lock phases."""
import json, sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "test-results/lifecycle-motion.json"
idle = (root / "omarchy/plugins/evangelion.magi-idle/Service.qml").read_text()
boot = (root / "bin/magi-boot-sequence").read_text()
launch = (root / "bin/omarchy-launch-screensaver").read_text()
saver = (root / "bin/magi-screensaver").read_text()
lock = (root / "omarchy/plugins/evangelion.lock/Service.qml").read_text()
checks = {
  "idle_uses_global_motion": 'evangelion.motion' in idle and 'motionMode: motion.mode' in idle,
  "idle_input_exit_immediate": 'else root.close()' in idle,
  "screensaver_retires_idle": launch.index('magi-idle hide') < launch.index('focused='),
  "lock_blocks_screensaver": 'lock isLocked' in launch,
  "boot_yields_each_step": boot.count('lifecycle_available || exit 0') >= 2,
  "boot_does_not_replay": 'magi-boot-sequence-$session' in boot and 'set -C' in boot,
  "global_modes_cover_boot": all(x in boot for x in ('mode == reduced', 'mode == off')),
  "global_modes_cover_saver": 'mode = motion_mode()' in saver and 'mode == "full"' in saver,
  "any_input_exits_saver": '?1003h' in saver and 'select.select' in saver and 'break' in saver,
  "lock_timer_authoritative": 'sessionLockStabilizeTimer' in lock and 'idleBlankTimer' in lock,
  "resume_guard": 'Date.now() - armedAt' in lock,
  "hidden_idle_has_no_repeating_animation": 'SequentialAnimation' not in idle and 'loops:' not in idle,
}
failed = [k for k,v in checks.items() if not v]
if failed: raise AssertionError(', '.join(failed))
report={"schema_version":1,"suite":"lifecycle-motion","status":"passed","checks":checks}
out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(report,indent=2)+"\n")
print(json.dumps(report))
