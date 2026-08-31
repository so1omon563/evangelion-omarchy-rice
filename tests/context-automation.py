#!/usr/bin/env python3
"""Exercise opt-in, holds, dry-run, cooldown, undo, and action bounds."""

import json
import importlib.machinery
import importlib.util
import os
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-context-automation"


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value) if isinstance(value, dict) else value)


def run(home, path, *args, **extra):
    env = {**os.environ, "HOME": str(home), "XDG_STATE_HOME": str(home / ".local/state"),
           "XDG_CONFIG_HOME": str(home / ".config"), "PATH": f"{path}:{os.environ['PATH']}", **extra}
    return subprocess.run([str(COMMAND), *args], env=env, text=True, capture_output=True, check=False)


def state(generation=7, enabled=True, actions=None):
    return {"schema_version": 1, "generation": generation,
            "controller": {"enabled": True, "automation_enabled": enabled,
                           "automation_rules": {"environment_profile": True}},
            "automatic_actions": actions or []}


def action(target="docked"):
    return {"id": f"profile-switch-{target}", "rule": "environment_profile",
            "action": "select-operating-profile", "target": target,
            "reason_code": f"environment-{target}"}


def main():
    source = COMMAND.read_text()
    assert "ALLOWED_RULES" in source and "ALLOWED_TARGETS" in source
    assert "manual-profile-selection" in source and "COOLDOWN_SECONDS = 300" in source
    profile_source = (ROOT / "bin/magi-operating-profile").read_text()
    for contract in ("capture_transaction", "restore_transaction", "failed_subsystem", "rolled_back"):
        assert contract in profile_source

    loader = importlib.machinery.SourceFileLoader("magi_context_controller", str(ROOT / "bin/magi-context"))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    controller = importlib.util.module_from_spec(spec)
    loader.exec_module(controller)
    config = dict(controller.DEFAULT_CONTEXT)
    config["collectors"] = dict(controller.DEFAULT_CONTEXT["collectors"])
    config["automation_rules"] = {"environment_profile": True}
    config["automation_enabled"] = True
    controller.resolved_config = lambda strict=False: ({}, config)
    observations = {
        "displays": {"available": True, "value": {"docked": True}},
        "operating_profile": {"available": True, "value": {"active": "mobile", "selected": "auto"}},
    }
    first = controller.build_state(1, 1, observations)
    second = controller.build_state(2, 2, observations, first)
    assert second["recommendations"][0]["requires_confirmation"] is True
    assert second["automatic_actions"] == [{"id": "profile-switch-docked", "rule": "environment_profile",
        "action": "select-operating-profile", "target": "docked",
        "reason_code": "profile-environment-mismatch", "requires_confirmation": False}]
    config["automation_rules"]["environment_profile"] = False
    assert controller.build_state(3, 3, observations, second)["automatic_actions"] == []

    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        fake = home / "bin"
        fake.mkdir()
        log = home / "profile.log"
        program = fake / "magi-operating-profile"
        program.write_text("#!/bin/sh\nprintf '%s\\n' \"$*\" >> \"$PROFILE_LOG\"\n"
                           "[ \"${PROFILE_FAIL:-0}\" = 1 ] && { echo '{\"failed_subsystem\":\"audio\"}'; exit 1; }\n"
                           "echo '{\"status\":\"applied\"}'\n")
        program.chmod(program.stat().st_mode | stat.S_IXUSR)
        context = home / ".local/state/evangelion-rice/context/state.json"
        mode = home / ".local/state/evangelion-rice/operating-profile/mode"
        write(mode, "auto\n")

        # Global opt-in is mandatory; recommendations can exist without execution.
        write(context, state(enabled=False, actions=[action()]))
        preview = json.loads(run(home, fake, "preview", "--json", PROFILE_LOG=str(log)).stdout)
        assert preview["reason"] == "global-kill-switch" and not log.exists()

        # Dock/undock is the only bounded rule. AC/battery, presentation,
        # thermal, and focus-shaped actions are deliberately rejected.
        unsafe = [action("presentation"), {**action(), "rule": "thermal"},
                  {**action(), "action": "launch-focus"}]
        write(context, state(actions=unsafe + [action("mobile")]))
        preview = json.loads(run(home, fake, "preview", "--json", PROFILE_LOG=str(log)).stdout)
        assert [item["target"] for item in preview["actions"]] == ["mobile"]

        dry = json.loads(run(home, fake, "apply", "--dry-run", "--json", PROFILE_LOG=str(log)).stdout)
        assert dry["reason"] == "ready" and not log.exists()
        applied = run(home, fake, "apply", "--json", PROFILE_LOG=str(log))
        assert applied.returncode == 0 and log.read_text().strip() == "context mobile"
        repeat = json.loads(run(home, fake, "apply", "--json", PROFILE_LOG=str(log)).stdout)
        assert repeat["reason"] == "already-applied"

        # Manual mode is a visible hold and always wins.
        write(mode, "docked\n")
        write(context, state(generation=8, actions=[action("mobile")]))
        held = json.loads(run(home, fake, "preview", "--json", PROFILE_LOG=str(log)).stdout)
        assert held["reason"] == "manual-hold" and "manual-profile-selection" in held["holds"]

        write(mode, "auto\n")
        automation = home / ".local/state/evangelion-rice/context/automation.json"
        runtime = json.loads(automation.read_text()); runtime["last_applied_at"] = 0
        write(automation, runtime)
        failed = run(home, fake, "apply", "--json", PROFILE_LOG=str(log), PROFILE_FAIL="1")
        assert failed.returncode == 1
        status = json.loads(run(home, fake, "status", "--json", PROFILE_LOG=str(log)).stdout)
        assert status["last_result"] == "failed" and status["last_failed_subsystem"] == "audio"

        runtime = json.loads(automation.read_text()); runtime["last_applied_at"] = 0
        write(automation, runtime)
        write(context, state(generation=9, actions=[]))
        undone = run(home, fake, "undo", "--json", PROFILE_LOG=str(log))
        assert undone.returncode == 0 and log.read_text().splitlines()[-1] == "undo"

        run(home, fake, "hold", "presentation", PROFILE_LOG=str(log))
        custom = json.loads(run(home, fake, "status", "--json", PROFILE_LOG=str(log)).stdout)
        assert "presentation" in custom["holds"]
        run(home, fake, "release", "presentation", PROFILE_LOG=str(log))

    print("PASS  bounded opt-in context automation, holds, rollback reporting, and undo")


if __name__ == "__main__":
    main()
