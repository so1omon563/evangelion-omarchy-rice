#!/usr/bin/env python3
"""Exercise static recovery activation, evidence, and exact restoration."""
import hashlib
import json
import os
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-recovery"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(env, *args, check=True):
    return subprocess.run([str(COMMAND), *args], env=env, text=True,
                          capture_output=True, check=check)


with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    home, config, state = base / "home", base / "config", base / "state"
    shell = config / "omarchy/shell.json"
    hypr = config / "hypr/hyprland.lua"
    shell.parent.mkdir(parents=True); hypr.parent.mkdir(parents=True)
    shell.write_text('{"private":"custom-shell"}\n')
    hypr.write_text('-- broken private config\nerror("broken")\n')
    shell.chmod(0o640); hypr.chmod(0o600)
    originals = {path: (digest(path), stat.S_IMODE(path.stat().st_mode)) for path in (shell, hypr)}
    env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(config),
           "XDG_STATE_HOME": str(state), "EVANGELION_SKIP_ACTIVATE": "1",
           "EVANGELION_RECOVERY_ROOT": str(ROOT / "recovery")}

    assert run(env, "status").stdout.strip() == "inactive"
    entered = run(env, "enter")
    assert "RECOVERY ACTIVE" in entered.stdout
    assert run(env, "status").stdout.strip() == "active"
    static = json.loads(shell.read_text())
    ids = [item["id"] for section in static["bar"]["layout"].values() for item in section]
    assert ids and all(item.startswith("omarchy.") for item in ids)
    assert static["plugins"] == [] and static["disabledPlugins"] == []
    assert "evangelion" not in shell.read_text().lower()
    assert "default.hypr.omarchy" in hypr.read_text()
    assert "hypr.monitors" not in hypr.read_text() and "hypr.bindings" not in hypr.read_text()
    evidence = json.loads(run(env, "evidence").stdout)
    assert evidence["schema_version"] == 1 and evidence["private_payloads"] is False
    assert not any(key in evidence for key in ("home", "host", "path", "error_output"))

    # Entering twice is idempotent and keeps the original recovery snapshot.
    active = (state / "evangelion-rice/recovery/active").resolve()
    assert "ALREADY ACTIVE" in run(env, "enter").stdout
    assert (state / "evangelion-rice/recovery/active").resolve() == active

    exited = run(env, "exit")
    assert "RECOVERY CLEARED" in exited.stdout
    assert run(env, "status").stdout.strip() == "inactive"
    for path, expected in originals.items():
        assert (digest(path), stat.S_IMODE(path.stat().st_mode)) == expected
    assert run(env, "exit").stdout.strip() == "RECOVERY NOT ACTIVE"

    # A mid-entry failure rolls back without advertising recovery as active.
    failed_env = {**env, "EVANGELION_FORCE_RECOVERY_FAILURE": "1"}
    failed = run(failed_env, "enter", check=False)
    assert failed.returncode != 0 and "original configuration restored" in failed.stderr
    assert run(env, "status").stdout.strip() == "inactive"
    for path, expected in originals.items():
        assert (digest(path), stat.S_IMODE(path.stat().st_mode)) == expected

    # Missing files are restored to absence, not invented during exit.
    shell.unlink(); hypr.unlink()
    run(env, "enter")
    assert shell.exists() and hypr.exists()
    run(env, "exit")
    assert not shell.exists() and not hypr.exists()

print("PASS  static recovery activation, evidence, idempotence, and exact restore")
