#!/usr/bin/env python3
"""Exercise the global motion controller in an isolated user environment."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-motion"


def run(home, *args, check=True):
    env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
           "XDG_STATE_HOME": str(home / ".local/state"), "EVANGELION_SKIP_RUNTIME": "1"}
    return subprocess.run([str(COMMAND), *args], env=env, text=True,
                          capture_output=True, check=check)


def main():
    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        assert run(home, "status").stdout.strip() == "full"
        default = json.loads(run(home, "show").stdout)
        assert default["mode"] == "full" and default["selected_mode"] == "full"
        assert default["profile"]["allow_blur"] is True
        assert default["tokens"]["durations_ms"]["standard"] == 180
        repository_tokens = json.loads((ROOT / "omarchy/motion.json").read_text())
        assert json.loads(run(home, "tokens").stdout) == repository_tokens
        capture = (ROOT / "bin/magi-capture").read_text()
        presentation = (ROOT / "bin/magi-presentation").read_text()
        assert "magi-motion hold screenshot" in capture and "magi-motion release screenshot" in capture
        assert "magi-motion hold recording" in capture and "magi-motion release recording" in capture
        assert "magi-motion hold presentation" in presentation and "magi-motion release presentation" in presentation

        config = home / ".config/omarchy/evangelion.json"
        config.parent.mkdir(parents=True)
        config.write_text('{"project_dir":"/srv/operator/project","custom":{"keep":true}}\n')
        assert run(home, "set", "reduced").stdout.strip() == "reduced"
        saved = json.loads(config.read_text())
        assert saved["motion"]["mode"] == "reduced"
        assert saved["project_dir"] == "/srv/operator/project" and saved["custom"]["keep"] is True
        assert run(home, "status").stdout.strip() == "reduced"

        state_path = home / ".local/state/evangelion-rice/motion/state.json"
        state = json.loads(state_path.read_text())
        assert state["mode"] == "reduced" and state["generation"] == 1
        assert state["profile"]["allow_scale"] is False
        assert run(home, "cycle").stdout.strip() == "full"
        assert json.loads(state_path.read_text())["generation"] == 2
        assert run(home, "cycle").stdout.strip() == "off"
        assert json.loads(run(home, "status", "--json").stdout)["profile"]["enabled"] is False

        run(home, "set", "full")
        assert run(home, "hold", "screen-share").stdout.strip() == "reduced"
        held = json.loads(run(home, "show").stdout)
        assert held["selected_mode"] == "full" and held["mode"] == "reduced"
        assert held["holds"] == ["screen-share"]
        assert run(home, "effective").stdout.strip() == "reduced"
        assert run(home, "release", "screen-share").stdout.strip() == "full"
        assert run(home, "holds", "--json").stdout.strip() == "[]"
        invalid_hold = run(home, "hold", "Private Path", check=False)
        assert invalid_hold.returncode == 2

        before = config.read_bytes()
        invalid = run(home, "set", "warp-speed", check=False)
        assert invalid.returncode == 2 and config.read_bytes() == before
        config.write_text("not json\n")
        invalid_config = run(home, "set", "full", check=False)
        assert invalid_config.returncode == 2 and config.read_text() == "not json\n"

    print("PASS  shared motion controller and upgrade-safe preference writes")


if __name__ == "__main__":
    main()
