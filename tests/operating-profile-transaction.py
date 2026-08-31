#!/usr/bin/env python3
"""Run the operating-profile transaction against isolated fake subsystems."""

import json
import os
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-operating-profile"


def main():
    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        bindir = home / "bin"; bindir.mkdir()
        config = home / ".config/omarchy"; config.mkdir(parents=True)
        state = home / ".local/state/evangelion-rice/operating-profile"; state.mkdir(parents=True)
        (config / "shell.toml").write_text("[bar]\nsize-horizontal = 26\nsize-vertical = 26\n")
        (config / "operating-profiles.json").write_text(json.dumps({
            "docked": {"power_profile": "performance", "bar_size": 30, "audio_target": "external",
                       "wallpaper": "keep", "display_layout": "extend-right"},
            "mobile": {"power_profile": "balanced", "bar_size": 26, "audio_target": "internal",
                       "wallpaper": "keep", "display_layout": "internal"}}))
        (state / "mode").write_text("auto\n"); (state / "active").write_text("mobile\n")
        dispatcher = bindir / "fake-subsystem"
        dispatcher.write_text(r'''#!/bin/sh
name=${0##*/}
case "$name:$*" in
  "hyprctl:monitors -j") echo '[{"id":0,"name":"eDP-1","width":1920,"height":1080,"x":0,"y":0,"scale":1},{"id":1,"name":"DP-1","width":1920,"height":1080,"x":1920,"y":0,"scale":1}]' ;;
  "hyprctl:clients -j") echo '[]' ;;
  hyprctl:eval*) exit 0 ;;
  "powerprofilesctl:list") printf '* balanced:\n  performance:\n' ;;
  "powerprofilesctl:get") echo balanced ;;
  powerprofilesctl:set*) echo "power:$2" >> "$PROFILE_LOG" ;;
  "pactl:-f json list sinks") echo '[{"name":"internal","properties":{"device.form_factor":"internal"}},{"name":"dock","properties":{"device.form_factor":"speaker","device.bus":"usb"}}]' ;;
  "pactl:get-default-sink") echo internal ;;
  pactl:set-default-sink*) echo "audio:$2" >> "$PROFILE_LOG"; [ "${FAIL_AUDIO:-0}" = 1 ] && exit 1; exit 0 ;;
  *) exit 0 ;;
esac
''')
        dispatcher.chmod(dispatcher.stat().st_mode | stat.S_IXUSR)
        for name in ("hyprctl", "powerprofilesctl", "pactl", "omarchy-shell",
                     "omarchy-notification-send", "omarchy-theme-bg-set"):
            (bindir / name).symlink_to(dispatcher)
        log = home / "profile.log"
        env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
               "XDG_STATE_HOME": str(home / ".local/state"), "PATH": f"{bindir}:{os.environ['PATH']}",
               "PROFILE_LOG": str(log), "FAIL_AUDIO": "1"}

        before = (config / "shell.toml").read_bytes()
        failed = subprocess.run(["bash", str(COMMAND), "context", "docked"], env=env,
                                text=True, capture_output=True, check=False)
        result = json.loads(failed.stdout.splitlines()[-1])
        assert failed.returncode == 1 and result == {"status": "failed", "rolled_back": True,
                                                     "failed_subsystem": "audio"}
        assert (config / "shell.toml").read_bytes() == before
        assert (state / "active").read_text().strip() == "mobile"

        env["FAIL_AUDIO"] = "0"
        applied = subprocess.run(["bash", str(COMMAND), "context", "docked"], env=env,
                                 text=True, capture_output=True, check=False)
        assert applied.returncode == 0 and json.loads(applied.stdout)["undo_available"] is True, (applied.returncode, applied.stdout, applied.stderr)
        assert "size-horizontal = 30" in (config / "shell.toml").read_text()
        assert (state / "active").read_text().strip() == "docked"
        undone = subprocess.run(["bash", str(COMMAND), "undo"], env=env, text=True,
                                capture_output=True, check=False)
        assert undone.returncode == 0 and json.loads(undone.stdout)["status"] == "undone"
        assert (config / "shell.toml").read_bytes() == before
        assert (state / "active").read_text().strip() == "mobile"

        (state / "mode").write_text("mobile\n")
        held = subprocess.run(["bash", str(COMMAND), "context", "docked"], env=env,
                              text=True, capture_output=True, check=False)
        assert held.returncode == 3 and json.loads(held.stdout)["failed_subsystem"] == "manual-profile-selection"

    print("PASS  operating-profile transaction rollback, undo, and manual authority")


if __name__ == "__main__":
    main()
