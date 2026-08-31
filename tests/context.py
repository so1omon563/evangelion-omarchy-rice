#!/usr/bin/env python3
"""Exercise the local MAGI context contract in an isolated user environment."""

import ast
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-context"
COLLECTORS = {"power", "thermal", "displays", "devices", "connectivity",
              "media", "time", "operating_profile"}


def environment(home, **extra):
    return {**os.environ, "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_STATE_HOME": str(home / ".local/state"), **extra}


def run(home, *args, check=True, **extra):
    return subprocess.run([str(COMMAND), *args], env=environment(home, **extra),
                          text=True, capture_output=True, check=check)


def main():
    tree = ast.parse(COMMAND.read_text())
    imported = {alias.name.split(".")[0] for node in ast.walk(tree)
                if isinstance(node, (ast.Import, ast.ImportFrom))
                for alias in (node.names if isinstance(node, ast.Import) else
                              [ast.alias(name=node.module or "")])}
    assert not imported.intersection({"requests", "urllib", "http", "socket", "subprocess"})

    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        initial = json.loads(run(home, "status", "--json").stdout)
        assert initial["schema_version"] == 1 and initial["generation"] == 0
        assert initial["derived_state"]["status"] == "unknown"
        assert set(initial["signals"]) == COLLECTORS
        assert initial["facts"] == {} and initial["recommendations"] == []
        assert initial["contract"]["availability_values"] == ["unknown", "available", "unavailable", "disabled"]
        assert initial["contract"]["freshness_values"] == ["unknown", "fresh", "stale", "disabled"]
        assert not (home / ".local/state/evangelion-rice/context/state.json").exists(), "status must be read-only"

        refreshed = json.loads(run(home, "refresh", "--json").stdout)
        assert refreshed["generation"] == 1 and refreshed["request_id"] == 1
        assert refreshed["signals"]["time"]["availability"] == "available"
        assert all(item["availability"] in {"available", "unavailable"} for item in refreshed["signals"].values())
        state_path = home / ".local/state/evangelion-rice/context/state.json"
        assert state_path.stat().st_mode & 0o777 == 0o600
        explanation = run(home, "explain").stdout
        assert any(code in explanation for code in ("policy-pending", "collectors-unavailable"))

        disabled = json.loads(run(home, "disable", "--json").stdout)
        assert disabled["derived_state"]["status"] == "disabled"
        assert all(item["availability"] == "disabled" for item in disabled["signals"].values())
        config_path = home / ".config/omarchy/evangelion.json"
        config = json.loads(config_path.read_text())
        assert config["context"]["enabled"] is False
        assert config["context"]["automation_enabled"] is False

        run(home, "enable")
        run(home, "automation", "enable")
        run(home, "decorative", "disable")
        run(home, "collector", "media", "disable")
        current = json.loads(run(home, "refresh", "--json").stdout)
        assert current["controller"]["automation_enabled"] is True
        assert current["controller"]["decorative_enabled"] is False
        assert current["signals"]["media"]["availability"] == "disabled"
        assert current["signals"]["power"]["availability"] in {"available", "unavailable"}

        config["custom"] = {"keep": True}
        config_path.write_text(json.dumps(config))
        run(home, "automation", "disable")
        saved = json.loads(config_path.read_text())
        assert saved["custom"] == {"keep": True}, "preference update replaced unrelated config"

        before = config_path.read_bytes()
        bad = run(home, "collector", "browser-history", "enable", check=False)
        assert bad.returncode == 2 and config_path.read_bytes() == before
        config_path.write_text("not json\n")
        bad = run(home, "disable", check=False)
        assert bad.returncode == 2 and config_path.read_text() == "not json\n"

    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        slow = subprocess.Popen([str(COMMAND), "refresh", "--json"],
                                env=environment(home, MAGI_CONTEXT_TEST_DELAY_MS="250"),
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(0.05)
        fast = json.loads(run(home, "refresh", "--json").stdout)
        slow_out, slow_err = slow.communicate(timeout=5)
        assert slow.returncode == 0, slow_err
        final = json.loads((home / ".local/state/evangelion-rice/context/state.json").read_text())
        requests = json.loads((home / ".local/state/evangelion-rice/context/requests.json").read_text())
        assert fast["request_id"] == requests["latest_request_id"] == final["request_id"] == 2
        assert final["generation"] == 1, "superseded request published stale state"
        assert json.loads(slow_out)["request_id"] == 2, "superseded caller did not receive latest state"

    print("PASS  local MAGI context schema, controller, and latest-request publication")


if __name__ == "__main__":
    main()
