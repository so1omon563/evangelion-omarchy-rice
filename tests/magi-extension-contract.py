#!/usr/bin/env python3
"""Conformance fixtures for the internal MAGI extension-state contract."""
import json
import os
import stat
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-extension-state"
SPEC = json.loads((ROOT / "magi-extension-contract.json").read_text())


def executable(path, body):
    path.write_text("#!/bin/sh\n" + body + "\n")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def invoke(fake):
    env = {**os.environ, "PATH": f"{fake}:/usr/bin:/bin"}
    return subprocess.run([str(COMMAND), "snapshot", "--json"], env=env,
                          text=True, capture_output=True, timeout=3, check=True)


assert SPEC["contract"] == "magi.extension-state"
assert SPEC["version"] == "1.0.0" and SPEC["scope"] == "suite-internal"
assert SPEC["standalone_runtime"] is False
assert SPEC["discovery"]["probe_timeout_ms"] <= 250
assert set(SPEC["capabilities"]) == {"affinity", "motion", "operating_profile", "settings", "health", "presentation"}

with tempfile.TemporaryDirectory() as directory:
    fake = Path(directory)
    executable(fake / "magi-affinity", 'if [ "$1" = palette ]; then printf \'{"label":"EVA-01 TEST TYPE"}\\n\'; else printf \'mode=auto\\nactive=unit-01\\n\'; fi')
    executable(fake / "magi-motion", "printf '%s\\n' '{\"schema_version\":1,\"selected_mode\":\"full\",\"mode\":\"reduced\",\"holds\":[\"presentation\"]}'")
    executable(fake / "magi-operating-profile", "printf 'mode=auto\\ndetected=docked\\neffective=docked\\nactive=docked\\n'")
    executable(fake / "eva-user-config", "printf '%s\\n' '{\"terminal\":\"private\",\"motion\":{\"mode\":\"full\"},\"context\":{\"enabled\":true,\"decorative_enabled\":true}}'")
    executable(fake / "magi-health", "printf '%s\\n' '{\"level\":\"nominal\",\"issues\":0,\"summary\":\"NOMINAL\",\"items\":[]}'")
    executable(fake / "magi-context", "printf '%s\\n' '{\"schema_version\":1,\"active\":true,\"status\":\"current\",\"freshness\":\"fresh\",\"signals\":[],\"recommendations\":[]}'")
    value = json.loads(invoke(fake).stdout)
    assert all(item["status"] == "compatible" for item in value["capabilities"].values())
    assert value["state"]["affinity"]["label"] == "EVA-01 TEST TYPE"
    assert value["state"]["motion"]["mode"] == "reduced"
    assert value["state"]["operating_profile"]["effective"] == "docked"
    assert value["state"]["settings"] == {"motion_mode": "full", "context_enabled": True, "decorative_enabled": True}
    assert "terminal" not in json.dumps(value["state"]["settings"])

    (fake / "magi-health").write_text("#!/bin/sh\nsleep 2\n")
    (fake / "magi-health").chmod(0o700)
    (fake / "magi-motion").write_text("#!/bin/sh\nprintf 'not-json\\n'\n")
    (fake / "magi-motion").chmod(0o700)
    (fake / "magi-context").unlink()
    started = time.monotonic()
    value = json.loads(invoke(fake).stdout)
    assert time.monotonic() - started < 1.5
    assert value["capabilities"]["health"]["status"] == "timed-out"
    assert value["capabilities"]["motion"]["status"] == "invalid"
    assert value["capabilities"]["presentation"]["status"] == "unavailable"
    for name in ("health", "motion", "presentation"):
        assert value["state"][name] == SPEC["capabilities"][name]["fallback"]

    for child in fake.iterdir():
        child.unlink()
    value = json.loads(invoke(fake).stdout)
    assert all(item["status"] == "unavailable" for item in value["capabilities"].values())
    assert value["state"] == {name: item["fallback"] for name, item in SPEC["capabilities"].items()}

serialized = json.dumps(value)
for prohibited in SPEC["privacy"]["prohibited"]:
    assert prohibited not in serialized

print("PASS  internal extension contract negotiation, timeouts, fallbacks, and privacy")
