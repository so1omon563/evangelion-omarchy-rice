#!/usr/bin/env python3
"""Verify context collector portability, freshness, and privacy boundaries."""

import importlib.util
import json
import os
import subprocess
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-context"
MODULE = ROOT / "lib/magi_context_collectors.py"


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(str(value) + "\n")


def load_collectors(sys_root, state_home, command_path):
    os.environ["EVA_SYS_ROOT"] = str(sys_root)
    os.environ["XDG_STATE_HOME"] = str(state_home)
    os.environ["MAGI_CONTEXT_COMMAND_PATH"] = str(command_path)
    spec = importlib.util.spec_from_file_location("fixture_collectors", MODULE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def cli(home, fixture, *args):
    env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
           "XDG_STATE_HOME": str(home / ".local/state"),
           "MAGI_CONTEXT_FIXTURE": str(fixture), "MAGI_CONTEXT_COMMAND_PATH": str(home / "empty-bin")}
    return subprocess.run([str(COMMAND), *args], env=env, text=True,
                          capture_output=True, check=True)


def full_fixture():
    return {
        "power": {"available": True, "value": {"source": "battery", "battery_percent": 64, "charging": False, "battery_count": 2}},
        "thermal": {"available": True, "value": {"temperature_c": 71.5, "pressure": "nominal", "sensor_count": 3}},
        "displays": {"available": True, "value": {"count": 2, "internal_count": 1, "external_count": 1, "docked": True}},
        "devices": {"available": True, "value": {"keyboards": 2, "pointers": 1, "audio_outputs": 2, "audio_inputs": 1}},
        "connectivity": {"available": True, "value": {"state": "connected"}},
        "media": {"available": True, "value": {"state": "playing", "player_count": 1, "playing_count": 1}},
        "time": {"available": True, "value": {"band": "afternoon", "weekend": False, "utc_offset_minutes": -420}},
        "operating_profile": {"available": True, "value": {"selected": "auto", "active": "docked"}},
    }


def main():
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        sys_root, state_home, empty_bin = root / "sys", root / "state", root / "bin"
        empty_bin.mkdir()
        bat0 = sys_root / "class/power_supply/BAT0"
        bat1 = sys_root / "class/power_supply/BAT1"
        ac = sys_root / "class/power_supply/AC"
        for bat, capacity in ((bat0, 60), (bat1, 80)):
            write(bat / "type", "Battery"); write(bat / "capacity", capacity); write(bat / "status", "Discharging")
        write(ac / "type", "Mains"); write(ac / "online", 0)
        write(sys_root / "class/hwmon/hwmon0/temp1_input", 72000)
        write(sys_root / "class/hwmon/hwmon0/temp2_input", 86000)
        write(state_home / "evangelion-rice/operating-profile/mode", "auto")
        write(state_home / "evangelion-rice/operating-profile/active", "mobile")
        collectors = load_collectors(sys_root, state_home, empty_bin)
        assert collectors.collect_power()["value"] == {"source": "battery", "battery_percent": 70,
                                                        "charging": False, "battery_count": 2}
        assert collectors.collect_thermal()["value"]["pressure"] == "high"
        assert collectors.collect_operating_profile()["value"] == {"selected": "auto", "active": "mobile"}
        assert collectors.collect_displays()["available"] is False
        assert collectors.collect_connectivity()["available"] is False
        assert collectors.collect_media()["available"] is False
        assert collectors.collect_time()["available"] is True

    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary); (home / "empty-bin").mkdir()
        fixture = home / "fixture.json"
        fixture.write_text(json.dumps(full_fixture()))
        state = json.loads(cli(home, fixture, "refresh", "--json").stdout)
        assert all(item["availability"] == "available" for item in state["signals"].values())
        assert state["derived_state"]["freshness"]["status"] == "fresh"
        assert state["facts"] == {"battery_percent": 64, "connectivity": "connected",
                                  "device_counts": {"keyboards": 2, "pointers": 1, "audio_outputs": 2, "audio_inputs": 1},
                                  "display_mode": "docked", "media_state": "playing",
                                  "operating_profile": "docked", "power_source": "battery",
                                  "profile_selection": "auto", "temperature_c": 71.5,
                                  "thermal_pressure": "nominal", "time_band": "afternoon", "weekend": False}
        serialized = json.dumps(state).lower()
        for forbidden in ("title", "artist", "ssid", "ip_address", "clipboard", "browser_history", "process_name"):
            assert forbidden not in serialized

        mismatch = full_fixture()
        mismatch["operating_profile"]["value"]["active"] = "mobile"
        fixture.write_text(json.dumps(mismatch))
        first_mismatch = json.loads(cli(home, fixture, "refresh", "--json").stdout)
        assert first_mismatch["recommendations"] == [], "profile mismatch was not debounced"
        second_mismatch = json.loads(cli(home, fixture, "refresh", "--json").stdout)
        assert second_mismatch["recommendations"][0]["target"] == "docked"
        assert second_mismatch["automatic_actions"] == [], "policy executed a recommendation"

        unsafe = full_fixture()
        unsafe["media"]["value"]["title"] = "private title"
        fixture.write_text(json.dumps(unsafe))
        rejected = json.loads(cli(home, fixture, "refresh", "--json").stdout)
        assert rejected["signals"]["media"]["availability"] == "available", "fresh cache should survive a rejected observation"
        assert rejected["signals"]["media"]["value"] == {"state": "playing", "player_count": 1, "playing_count": 1}
        assert "private title" not in json.dumps(rejected)

        unsafe = full_fixture()
        unsafe["connectivity"]["value"]["state"] = "private-network-name"
        fixture.write_text(json.dumps(unsafe))
        rejected_value = json.loads(cli(home, fixture, "refresh", "--json").stdout)
        assert rejected_value["signals"]["connectivity"]["reason"] == "cached-observation"
        assert "private-network-name" not in json.dumps(rejected_value)

        config_path = home / ".config/omarchy/evangelion.json"
        config = json.loads(config_path.read_text()) if config_path.exists() else {}
        config["context"] = {"enabled": True, "automation_enabled": False, "decorative_enabled": True,
                             "max_age_seconds": 1, "collectors": {name: True for name in full_fixture()}}
        config_path.parent.mkdir(parents=True, exist_ok=True); config_path.write_text(json.dumps(config))
        state_path = home / ".local/state/evangelion-rice/context/state.json"
        old = json.loads(state_path.read_text())
        old_time = (datetime.now(timezone.utc) - timedelta(seconds=10)).isoformat().replace("+00:00", "Z")
        for item in old["signals"].values():
            item["freshness"]["observed_at"] = old_time
        state_path.write_text(json.dumps(old))
        unavailable = {name: {"available": False, "reason": "unavailable"} for name in full_fixture()}
        fixture.write_text(json.dumps(unavailable))
        stale = json.loads(cli(home, fixture, "refresh", "--json").stdout)
        assert all(item["freshness"]["status"] == "stale" for item in stale["signals"].values())
        assert stale["derived_state"]["freshness"]["status"] == "stale"
        assert any(reason["code"] == "stale-observations" for reason in stale["reasons"])

    print("PASS  capability-aware local collectors, stale cache, and privacy schema")


if __name__ == "__main__":
    main()
