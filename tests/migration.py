#!/usr/bin/env python3
"""Versioned migration preview, choices, rollback, and recovery fixtures."""
import hashlib
import json
import os
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-migrate"


def run(env, *args, check=True):
    return subprocess.run([str(COMMAND), *args], env=env, text=True, capture_output=True, check=check)


def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest(), stat.S_IMODE(path.stat().st_mode)


with tempfile.TemporaryDirectory() as directory:
    base = Path(directory); config = base / "config"; state = base / "state"
    env = {**os.environ, "HOME": str(base / "home"), "XDG_CONFIG_HOME": str(config),
           "XDG_STATE_HOME": str(state), "EVANGELION_MIGRATION_ROOT": str(ROOT),
           "EVANGELION_SKIP_ACTIVATE": "1"}
    fixtures = {
        "omarchy/shell.json": '{"user":"shell"}\n',
        "hypr/hyprland.lua": '-- user hyprland\n',
        "hypr/bindings.lua": '-- user bindings\n',
        "hypr/looknfeel.lua": '-- user looknfeel\n',
    }
    for relative, content in fixtures.items():
        path = config / relative; path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content); path.chmod(0o600)
    before = {name: fingerprint(config / name) for name in fixtures}
    state_before = sorted(str(path.relative_to(base)) for path in base.rglob("*"))

    preview = json.loads(run(env, "preview", "--json").stdout)
    assert preview["source_version"] == "1.4.1" and preview["target_version"] == "1.5.0"
    assert all(item["status"] == "conflict" and item["replacement_required"] for item in preview["operations"])
    assert len(preview["required_actions"]) == 4 and preview["read_only"] is True
    assert sorted(str(path.relative_to(base)) for path in base.rglob("*")) == state_before
    assert "omarchy/evangelion.json" in preview["preserved"]

    unresolved = run(env, "apply", check=False)
    assert unresolved.returncode == 2 and "Unresolved conflicts" in unresolved.stderr
    assert {name: fingerprint(config / name) for name in fixtures} == before
    unknown = run(env, "apply", "--resolve", "imaginary=keep", check=False)
    assert unknown.returncode == 2 and "Unknown conflict IDs" in unknown.stderr

    applied = json.loads(run(env, "apply", "--json", "--resolve", "shell=keep",
                             "--resolve", "hyprland=replace", "--resolve", "bindings=replace",
                             "--resolve", "looknfeel=replace").stdout)
    snapshot = Path(applied["snapshot"])
    assert (config / "omarchy/shell.json").read_text() == fixtures["omarchy/shell.json"]
    assert (config / "hypr/hyprland.lua").read_bytes() == (ROOT / "hypr/hyprland.lua").read_bytes()
    assert (state / "evangelion-rice/migrations/installed-version").read_text().strip() == "1.5.0"
    journal = json.loads((snapshot / "journal.json").read_text())
    assert journal["state"] == "completed"
    assert {item["id"]: item["action"] for item in journal["operations"]}["shell"] == "keep"

    run(env, "rollback", str(snapshot))
    assert {name: fingerprint(config / name) for name in fixtures} == before
    assert not (state / "evangelion-rice/migrations/installed-version").exists()

    failed_env = {**env, "EVANGELION_FORCE_MIGRATION_FAILURE": "1"}
    failed = run(failed_env, "apply", "--resolve", "shell=replace", "--resolve", "hyprland=replace",
                 "--resolve", "bindings=replace", "--resolve", "looknfeel=replace", check=False)
    assert failed.returncode == 2
    status = json.loads(run(env, "status", "--json").stdout)
    assert status["interrupted"] is True
    blocked = run(env, "apply", check=False)
    assert blocked.returncode == 2 and "Interrupted migration" in blocked.stderr
    run(env, "recover")
    assert {name: fingerprint(config / name) for name in fixtures} == before
    assert json.loads(run(env, "status", "--json").stdout)["interrupted"] is False

print("PASS  migration preview, explicit choices, exact rollback, and interruption recovery")
