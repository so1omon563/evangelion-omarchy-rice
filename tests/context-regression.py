#!/usr/bin/env python3
"""Context restart, interruption, migration, and end-to-end privacy regressions."""

import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-context"
COLLECTORS = ("power", "thermal", "displays", "devices", "connectivity",
              "media", "time", "operating_profile")
SECRETS = {
    "title": "PRIVATE_TRACK_7D91",
    "artist": "PRIVATE_ARTIST_8E02",
    "ssid": "PRIVATE_WIFI_9F13",
    "ip_address": "198.51.100.77",
    "clipboard": "PRIVATE_CLIPBOARD_A024",
    "browser_history": "PRIVATE_HISTORY_B135",
    "process_name": "PRIVATE_PROCESS_C246",
}


def environment(home, fixture=None, **extra):
    env = {**os.environ, "HOME": str(home),
           "XDG_CONFIG_HOME": str(home / ".config"),
           "XDG_STATE_HOME": str(home / ".local/state"),
           "MAGI_CONTEXT_COMMAND_PATH": str(home / "empty-bin"), **extra}
    if fixture:
        env["MAGI_CONTEXT_FIXTURE"] = str(fixture)
    return env


def run(home, fixture, *args, check=True, **extra):
    return subprocess.run([str(COMMAND), *args], env=environment(home, fixture, **extra),
                          text=True, capture_output=True, check=check)


def safe_fixture():
    return {
        "power": {"available": True, "value": {"source": "ac", "battery_percent": 82,
                  "charging": False, "battery_count": 2}},
        "thermal": {"available": True, "value": {"temperature_c": 48.0,
                    "pressure": "nominal", "sensor_count": 3}},
        "displays": {"available": True, "value": {"count": 1, "internal_count": 1,
                    "external_count": 0, "docked": False}},
        "devices": {"available": True, "value": {"keyboards": 1, "pointers": 1,
                   "audio_outputs": 1, "audio_inputs": 1}},
        "connectivity": {"available": True, "value": {"state": "connected"}},
        "media": {"available": True, "value": {"state": "paused", "player_count": 1,
                  "playing_count": 0}},
        "time": {"available": True, "value": {"band": "afternoon", "weekend": False,
                 "utc_offset_minutes": -420}},
        "operating_profile": {"available": True, "value": {"selected": "auto", "active": "mobile"}},
    }


def assert_private_values_absent(blobs):
    combined = "\n".join(blobs)
    for value in SECRETS.values():
        assert value not in combined, f"private sentinel leaked: {value}"


def main():
    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        (home / "empty-bin").mkdir()
        fixture = home / "fixture.json"
        state_path = home / ".local/state/evangelion-rice/context/state.json"
        request_path = home / ".local/state/evangelion-rice/context/requests.json"

        # An incompatible persisted schema is ignored without being rewritten by
        # read-only status; the next explicit refresh migrates to the current v1.
        state_path.parent.mkdir(parents=True)
        legacy = {"schema_version": 0, "generation": 900, "private": SECRETS}
        state_path.write_text(json.dumps(legacy))
        before = state_path.read_bytes()
        fallback = json.loads(run(home, fixture, "status", "--json", "--compact").stdout)
        assert fallback["schema_version"] == 1 and fallback["generation"] == 0
        assert state_path.read_bytes() == before, "read-only migration fallback rewrote legacy state"

        fixture.write_text(json.dumps(safe_fixture()))
        migrated = json.loads(run(home, fixture, "refresh", "--json", "--compact").stdout)
        assert migrated["schema_version"] == 1 and migrated["generation"] == 1
        assert json.loads(state_path.read_text())["schema_version"] == 1

        # Independent CLI processes resume monotonic request and generation state.
        restarted = json.loads(run(home, fixture, "refresh", "--json", "--compact").stdout)
        assert restarted["request_id"] == migrated["request_id"] + 1
        assert restarted["generation"] == migrated["generation"] + 1

        # Kill a refresh between reservation and publication. A new process must
        # recover, win publication, and leave no partial JSON behind.
        interrupted = subprocess.Popen([str(COMMAND), "refresh", "--json", "--compact"],
            env=environment(home, fixture, MAGI_CONTEXT_TEST_DELAY_MS="1500"),
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(0.12)
        interrupted.terminate()
        interrupted.communicate(timeout=3)
        recovered = json.loads(run(home, fixture, "refresh", "--json", "--compact").stdout)
        requests = json.loads(request_path.read_text())
        published = json.loads(state_path.read_text())
        assert published["request_id"] == requests["latest_request_id"] == recovered["request_id"]
        assert published["generation"] == restarted["generation"] + 1

        # A burst of contradictory refreshes converges on the final request and
        # every persisted controller artifact remains valid JSON.
        workers = []
        for delay in (240, 180, 120, 60, 0):
            workers.append(subprocess.Popen([str(COMMAND), "refresh", "--json", "--compact"],
                env=environment(home, fixture, MAGI_CONTEXT_TEST_DELAY_MS=str(delay)),
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
            time.sleep(0.02)
        outputs = [worker.communicate(timeout=5) for worker in workers]
        assert all(worker.returncode == 0 for worker in workers)
        requests = json.loads(request_path.read_text())
        published = json.loads(state_path.read_text())
        assert published["request_id"] == requests["latest_request_id"]

        # Private fields at the collector boundary are rejected. Check every
        # externally observable channel, not only the normalized state object.
        unsafe = safe_fixture()
        for observation in unsafe.values():
            observation["value"].update(SECRETS)
        fixture.write_text(json.dumps(unsafe))
        result = run(home, fixture, "refresh", "--json", "--compact")
        explanation = run(home, fixture, "explain")
        surface = run(home, fixture, "surface", "--json", "--compact")
        blobs = [result.stdout, result.stderr, explanation.stdout, explanation.stderr,
                 surface.stdout, surface.stderr, state_path.read_text(), request_path.read_text()]
        blobs.extend(stdout + stderr for stdout, stderr in outputs)
        for directory in (ROOT / "captures", ROOT / "test-results"):
            for path in directory.glob("*.json"):
                blobs.append(path.read_text(errors="replace"))
        assert_private_values_absent(blobs)

        unavailable = {name: {"available": False, "reason": "missing-capability"}
                       for name in COLLECTORS}
        fixture.write_text(json.dumps(unavailable))
        unavailable_state = json.loads(run(home, fixture, "refresh", "--json", "--compact").stdout)
        assert all(item["availability"] in {"available", "unavailable"}
                   for item in unavailable_state["signals"].values())

    # Keep the acceptance map explicit so future test deletion cannot silently
    # erase the existing precedence, hold, rollback, stale, and safety coverage.
    contracts = {
        "precedence": (ROOT / "tests/context-policy.py", "precedence ="),
        "stale": (ROOT / "tests/context-collectors.py", "stale-observations"),
        "holds": (ROOT / "tests/context-automation.py", "manual-hold"),
        "rollback": (ROOT / "tests/operating-profile-transaction.py", "rolled_back"),
        "clean-user": (ROOT / "tests/clean-user.sh", "fresh clean-user full install"),
        "motion-safety": (ROOT / "tests/lock-motion.py", "secure"),
    }
    for name, (path, marker) in contracts.items():
        assert marker in path.read_text(), f"missing {name} regression contract"

    print("PASS  context migration, restart, interruption, privacy, and regression contracts")


if __name__ == "__main__":
    main()
