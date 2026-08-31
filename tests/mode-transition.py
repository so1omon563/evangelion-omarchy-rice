#!/usr/bin/env python3
"""Static safety contracts for reversible operating-mode transitions."""
import json, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]) if len(sys.argv)>1 else root/"test-results/mode-transition.json"
service=(root/"omarchy/plugins/evangelion.mode-transition/Service.qml").read_text()
deployment=(root/"bin/magi-deployment").read_text()
presentation=(root/"bin/magi-presentation").read_text()
focus=(root/"bin/magi-focus").read_text()
intrusion=(root/"bin/magi-intrusion").read_text()
operating=(root/"bin/magi-operating-profile").read_text()
terminal=(root/"bin/magi-terminal-context").read_text()
shell=json.loads((root/"omarchy/shell.json").read_text())
modes=("presentation","deployment","at-field","angel","docked","mobile","terminal-context")
checks={
 "all_mode_families":all(f'"{m}"' in service for m in modes),
 "service_enabled":any(p["id"]=="evangelion.mode-transition" for p in shell["plugins"]),
 "never_takes_focus":'WlrKeyboardFocus.None' in service and 'mask:Region{}' in service,
 "does_not_obscure_desktop":'height:104' in service and 'anchors.bottom' in service,
 "all_motion_modes":all(x in service for x in ('motion.full','motion.reduced','motion.off')),
 "deployment_no_duplicates":'if session_active' in deployment and 'Existing mission layout focused' in deployment,
 "deployment_partial_rollback":'if (( failed ))' in deployment and 'teardown' in deployment and 'Partial launch rolled back' in deployment,
 "deployment_exact_clients":'client_still_matches' in deployment and '.address,.pid,.class' in deployment,
 "presentation_partial_rollback":'trap cleanup_failed ERR' in presentation and 'magi-motion release presentation' in presentation,
 "presentation_wallpaper_aware":'layout_for_background' in presentation and 'geometry_for_monitor' in presentation,
 "at_field_transaction":'snapshot_dir' in focus and 'AT Field activation failed; previous state restored.' in focus,
 "angel_manual_safe_exit":'MANUAL' not in intrusion and 'magi-intrusion exit' in intrusion and 'restore_session' in intrusion,
 "angel_failure_restore":'activation failed; restoring captured state' in intrusion,
 "dock_window_rescue":'rescue_windows' in operating and 'valid == true' in operating,
 "terminal_isolated":'EVA_TERMINAL_CONTEXT_PROFILE' in terminal and 'os.execve' in terminal,
}
failed=[k for k,v in checks.items() if not v]
if failed:raise AssertionError(', '.join(failed))
report={"schema_version":1,"suite":"mode-transition","status":"passed","checks":checks,"modes":modes}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2)+"\n");print(json.dumps(report))
