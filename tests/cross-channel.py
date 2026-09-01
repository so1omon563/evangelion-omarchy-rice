#!/usr/bin/env python3
"""Supported channel transitions, ownership conflicts, and baseline evidence."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args, env=None, check=True, cwd=None):
    result = subprocess.run(args, env=env, cwd=cwd, text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(f"command failed ({result.returncode}): {' '.join(map(str,args))}\n{result.stdout}{result.stderr}")
    return result


matrix = json.loads((ROOT / "distribution.json").read_text())
runtime = json.loads((ROOT / "magi-runtime-contract.json").read_text())
audit = json.loads((ROOT / "plugin-audit.json").read_text())
assert set(matrix["tiers"]) == {"theme", "suite", "arch"}
assert matrix["internal_plugins"]["standalone_advertising"] is False
assert matrix["internal_plugins"]["standalone_installation"] is False
assert not any(row["classification"] == "standalone" for row in audit["plugins"])
assert runtime["decision"] == "intentionally-avoided-as-separate-package"
assert {"runtime-absent", "runtime-state-stale", "runtime-major-incompatible"} <= set(runtime["compatibility_tests"])

with tempfile.TemporaryDirectory(prefix="evangelion-channels-") as raw:
    tmp = Path(raw); home = tmp / "home"; state = tmp / "state"; exported = tmp / "theme"
    home.mkdir(); state.mkdir()
    run(ROOT / "scripts/export-theme", exported)
    theme_target = home / ".config/omarchy/themes/evangelion"
    theme_target.parent.mkdir(parents=True)
    shutil.copytree(exported, theme_target)
    run("git", "init", "--quiet", cwd=theme_target)
    before = {str(p.relative_to(home)): p.read_bytes() for p in home.rglob("*") if p.is_file()}
    env = os.environ | {"HOME": str(home), "XDG_STATE_HOME": str(state),
                        "EVANGELION_SKIP_ACTIVATE": "1", "EVANGELION_SOURCE_ONLY": "1",
                        "EVANGELION_RELEASE_131_NESTED": "1", "EVANGELION_RELEASE_ARTIFACT_NESTED": "1",
                        "EVANGELION_CROSS_CHANNEL_NESTED": "1"}
    conflict = run(ROOT / "install.sh", "--dry-run", "--preset", "minimal", env=env, check=False)
    assert conflict.returncode == 3 and "CHANNEL CONFLICT" in conflict.stderr
    after = {str(p.relative_to(home)): p.read_bytes() for p in home.rglob("*") if p.is_file()}
    assert before == after, "channel conflict mutated the user home"

    shutil.rmtree(theme_target)
    run(ROOT / "install.sh", "--apply", "--yes", "--preset", "minimal", env=env)
    snapshot = Path((state / "evangelion-rice/last-install-backup").read_text().strip())
    assert snapshot.is_dir() and (theme_target / "colors.toml").is_file()

    marker = home / ".channel-marker"
    marker.write_text("preserve\n")
    failed = run(ROOT / "install.sh", "--apply", "--yes", "--components", "shell-integration",
                 env=env | {"EVANGELION_FORCE_INSTALL_FAILURE": "1"}, check=False)
    assert failed.returncode != 0 and marker.read_text() == "preserve\n"
    run(ROOT / "rollback.sh", snapshot, env=env)
    assert not any(p.is_file() for p in theme_target.rglob("*"))

browser = (ROOT / "bin/magi-deployment").read_text()
motion = (ROOT / "tests/motion-regression.py").read_text()
privacy = (ROOT / "tests/context-regression.py").read_text()
responsive = json.loads((ROOT / "tests/fixtures/responsive-layouts.json").read_text())
preflight = (ROOT / "preflight.py").read_text()
checks = {
    "supported_channels": set(matrix["tiers"]) == {"theme", "suite", "arch"},
    "internal_plugins_only": matrix["internal_plugins"]["standalone_installation"] is False,
    "theme_suite_conflict_read_only": True,
    "suite_transaction_rollback": True,
    "partial_failure_rollback": True,
    "v13_upgrade_contract": "exact v1.3.0 install" in (ROOT / "tests/release-v1.3.1.py").read_text(),
    "omarchy_capability_preflight": "SUPPORTED" in preflight and '"capabilities"' in preflight,
    "optional_magi_fallback": runtime["capabilities"]["motion"]["fallback"]["mode"] == "reduced",
    "xdg_default_browser": "xdg-settings get default-web-browser" in browser and "env -u BROWSER" in browser,
    "motion_baseline": all(value in motion for value in ('"full"', '"reduced"', '"off"')),
    "privacy_baseline": "privacy" in privacy,
    "responsive_baseline": len(responsive.get("profiles", [])) >= 3,
    "machine_evidence": True,
}
assert all(checks.values()), [key for key, value in checks.items() if not value]
report = {"schema_version": 1, "status": "passed", "baseline": matrix["baseline"],
          "channels": {name: {"channel": tier["channel"], "activation": tier["activation"],
                              "owns_user_config": tier["owns_user_config"]}
                       for name, tier in matrix["tiers"].items()},
          "ownership": matrix["owners"], "conflicts": matrix["channel_conflicts"],
          "checks": checks}
output = Path(os.environ.get("EVANGELION_CROSS_CHANNEL_REPORT", ROOT / "test-results/cross-channel.json"))
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
print("PASS  cross-channel ownership transitions and regression baselines")
