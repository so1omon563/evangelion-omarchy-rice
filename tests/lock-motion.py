#!/usr/bin/env python3
"""Portable safety contract for lock/auth/session-control motion."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "test-results/lock-motion.json"
service = (ROOT / "omarchy/plugins/evangelion.lock/Service.qml").read_text()
view = (ROOT / "omarchy/plugins/evangelion.lock/LockView.qml").read_text()
menu = (ROOT / "omarchy/extensions/omarchy-menu.jsonc").read_text()

checks = {}
def check(name, condition):
    checks[name] = bool(condition)
    if not condition:
        raise AssertionError(name)

begin = re.search(r"function beginLock\(\).*?\n  }", service, re.S).group(0)
check("request_precedes_session_queue", begin.index("lockRequested = true") < begin.index("queueSessionLock()"))
check("opaque_secure_surface", "WlSessionLockSurface" in service and "color: Color.background" in service and "anchors.fill: parent" in service)
check("secure_surface_not_animated", not re.search(r"WlSessionLockSurface\s*\{[^}]*\b(?:Behavior|Animation)\b", service, re.S))
check("motion_reaches_real_and_preview", service.count("motionMode: motion.mode") >= 2)
check("mode_aware_granted_dwell", "motion.full ? 320 : (motion.reduced ? 100 : 0)" in service)
check("masked_password", "echoMode: TextInput.Password" in view and "passwordMaskDelay: 0" in view)
check("input_frozen_while_checking", "!root.authenticatingPassword && !root.authorizationGranted" in view and "readOnly: root.authenticatingPassword || root.authorizationGranted" in view)
failure = re.search(r"function handlePasswordFailure\(\).*?\n  }", service, re.S).group(0)
check("failure_clears_secret", 'enteredPassword = ""' in failure and 'pendingPassword = ""' in failure)
check("secret_not_logged", "console.log" in service and not re.search(r"console\.log\([^\n]*(?:pendingPassword|enteredPassword)", service))
check("fixed_noninteractive_feedback", "id: authorizationRail" in view and "anchors.horizontalCenter" in view and "MouseArea" not in re.search(r"id: authorizationRail.*?\n    }", view, re.S).group(0))
check("controls_do_not_move", not re.search(r"Behavior on (?:x|y|scale|opacity)", view))
check("resume_wall_clock_guard", "Date.now() - armedAt" in service)
check("restart_recovery", "recoverStrandedLock()" in service and "pendingSessionLockTimer" in service)
check("preview_all_auth_states", all(f"function {name}()" in service for name in ("preview", "previewChecking", "previewFailure", "previewGranted", "hidePreview")))

for action in ("logout", "reboot", "shutdown"):
    parent = re.search(rf'"system\.{action}"\s*:\s*\{{.*?\n  \}}', menu, re.S).group(0)
    check(f"{action}_requires_confirmation", '"action": ""' in parent)
    check(f"{action}_abort_precedes_execute", menu.index(f'"system.{action}.abort"') < menu.index(f'"system.{action}.execute"'))
check("cancel_is_noop", re.search(r'"system\.cancel".*?"action": "true"', menu, re.S) is not None)

report = {"schema_version": 1, "suite": "lock-motion", "status": "passed", "checks": checks}
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report))
