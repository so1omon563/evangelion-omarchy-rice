"""Privacy-bounded, read-only local collectors for MAGI context."""

import json
import os
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

SYS_ROOT = Path(os.environ.get("EVA_SYS_ROOT", "/sys"))
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
COMMAND_PATH = os.environ.get("MAGI_CONTEXT_COMMAND_PATH")
TIMEOUT_SECONDS = 2


def result(available, value=None, reason="observed"):
    return {"available": bool(available), "value": value if available else None,
            "reason": reason}


def command(name):
    return shutil.which(name, path=COMMAND_PATH)


def run_text(args):
    try:
        completed = subprocess.run(args, text=True, capture_output=True,
                                   timeout=TIMEOUT_SECONDS, check=False)
        return completed.stdout.strip() if completed.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def run_json(args):
    try:
        value = json.loads(run_text(args))
        return value
    except (TypeError, json.JSONDecodeError):
        return None


def integer(path):
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def text(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def collect_power():
    root = SYS_ROOT / "class/power_supply"
    batteries = []
    mains_online = False
    for item in root.glob("*"):
        kind = text(item / "type").lower()
        if kind == "battery" or item.name.startswith("BAT"):
            capacity = integer(item / "capacity")
            status = text(item / "status").lower()
            if capacity is not None:
                batteries.append((max(0, min(100, capacity)), status))
        elif kind in {"mains", "usb", "usb_c"} and integer(item / "online") == 1:
            mains_online = True
    if not batteries and not mains_online:
        return result(False, reason="power-supply-unavailable")
    statuses = [status for _, status in batteries]
    charging = True if any(status == "charging" for status in statuses) else (
        False if any(status == "discharging" for status in statuses) else None)
    source = "ac" if mains_online or charging is True else "battery" if batteries else "unknown"
    percent = round(sum(value for value, _ in batteries) / len(batteries)) if batteries else None
    return result(True, {"source": source, "battery_percent": percent,
                         "charging": charging, "battery_count": len(batteries)})


def collect_thermal():
    readings = []
    for hwmon in (SYS_ROOT / "class/hwmon").glob("hwmon*"):
        for path in hwmon.glob("temp*_input"):
            value = integer(path)
            if value is not None and 5000 <= value <= 120000:
                readings.append(value / 1000)
    if not readings:
        for zone in (SYS_ROOT / "class/thermal").glob("thermal_zone*"):
            value = integer(zone / "temp")
            if value is not None and 5000 <= value <= 120000:
                readings.append(value / 1000)
    if not readings:
        return result(False, reason="thermal-sensors-unavailable")
    maximum = round(max(readings), 1)
    pressure = "critical" if maximum >= 95 else "high" if maximum >= 85 else "elevated" if maximum >= 75 else "nominal"
    return result(True, {"temperature_c": maximum, "pressure": pressure,
                         "sensor_count": len(readings)})


def collect_displays():
    executable = command("hyprctl")
    monitors = run_json([executable, "monitors", "-j"]) if executable else None
    if not isinstance(monitors, list):
        return result(False, reason="display-ipc-unavailable")
    internal = sum(1 for item in monitors if str(item.get("name", "")).startswith(("eDP-", "LVDS-", "DSI-")))
    external = max(0, len(monitors) - internal)
    return result(True, {"count": len(monitors), "internal_count": internal,
                         "external_count": external, "docked": external > 0})


def collect_devices():
    value = {"keyboards": None, "pointers": None, "audio_outputs": None, "audio_inputs": None}
    observed = False
    hyprctl = command("hyprctl")
    devices = run_json([hyprctl, "devices", "-j"]) if hyprctl else None
    if isinstance(devices, dict):
        value["keyboards"] = len(devices.get("keyboards", []))
        value["pointers"] = sum(len(devices.get(key, [])) for key in ("mice", "touch", "tablets"))
        observed = True
    pactl = command("pactl")
    if pactl:
        sinks = run_json([pactl, "-f", "json", "list", "sinks"])
        sources = run_json([pactl, "-f", "json", "list", "sources"])
        if isinstance(sinks, list):
            value["audio_outputs"] = len(sinks)
            observed = True
        if isinstance(sources, list):
            value["audio_inputs"] = len(sources)
            observed = True
    return result(observed, value, "observed" if observed else "device-ipc-unavailable")


def collect_connectivity():
    nmcli = command("nmcli")
    if not nmcli:
        return result(False, reason="network-manager-unavailable")
    raw = run_text([nmcli, "-t", "-f", "STATE", "general"]).lower()
    if not raw:
        return result(False, reason="network-manager-unavailable")
    state = "connected" if raw.startswith("connected") else "local" if "local" in raw else "disconnected" if raw.startswith("disconnected") else "unknown"
    return result(True, {"state": state})


def collect_media():
    playerctl = command("playerctl")
    if not playerctl:
        return result(False, reason="mpris-tools-unavailable")
    players = [line for line in run_text([playerctl, "-l"]).splitlines() if line]
    states = [run_text([playerctl, "--player", player, "status"]).lower() for player in players]
    playing = sum(state == "playing" for state in states)
    state = "playing" if playing else "paused" if any(item == "paused" for item in states) else "idle"
    return result(True, {"state": state, "player_count": len(players),
                         "playing_count": playing})


def collect_time():
    now = datetime.now().astimezone()
    hour = now.hour
    band = "night" if hour < 6 or hour >= 22 else "morning" if hour < 12 else "afternoon" if hour < 18 else "evening"
    return result(True, {"band": band, "weekend": now.weekday() >= 5,
                         "utc_offset_minutes": int((now.utcoffset().total_seconds() if now.utcoffset() else 0) / 60)})


def collect_operating_profile():
    root = STATE_HOME / "evangelion-rice/operating-profile"
    selected = text(root / "mode") or "auto"
    active = text(root / "active") or "unknown"
    if selected not in {"auto", "docked", "mobile"}:
        selected = "unknown"
    if active not in {"docked", "mobile"}:
        active = "unknown"
    return result(True, {"selected": selected, "active": active})


COLLECTOR_FUNCTIONS = {
    "power": collect_power,
    "thermal": collect_thermal,
    "displays": collect_displays,
    "devices": collect_devices,
    "connectivity": collect_connectivity,
    "media": collect_media,
    "time": collect_time,
    "operating_profile": collect_operating_profile,
}

VALUE_KEYS = {
    "power": {"source", "battery_percent", "charging", "battery_count"},
    "thermal": {"temperature_c", "pressure", "sensor_count"},
    "displays": {"count", "internal_count", "external_count", "docked"},
    "devices": {"keyboards", "pointers", "audio_outputs", "audio_inputs"},
    "connectivity": {"state"},
    "media": {"state", "player_count", "playing_count"},
    "time": {"band", "weekend", "utc_offset_minutes"},
    "operating_profile": {"selected", "active"},
}
REASON_CODES = {"observed", "power-supply-unavailable", "thermal-sensors-unavailable",
                "display-ipc-unavailable", "device-ipc-unavailable",
                "network-manager-unavailable", "mpris-tools-unavailable",
                "invalid-observation", "privacy-schema-rejected", "fixture-unavailable",
                "collector-failed", "unavailable"}


def natural(value, nullable=False):
    return (nullable and value is None) or (isinstance(value, int) and not isinstance(value, bool) and value >= 0)


def valid_value(name, value):
    if name == "power":
        return (value["source"] in {"ac", "battery", "unknown"}
                and (value["battery_percent"] is None or natural(value["battery_percent"]) and value["battery_percent"] <= 100)
                and (value["charging"] is None or isinstance(value["charging"], bool))
                and natural(value["battery_count"]))
    if name == "thermal":
        return (isinstance(value["temperature_c"], (int, float)) and not isinstance(value["temperature_c"], bool)
                and 5 <= value["temperature_c"] <= 120
                and value["pressure"] in {"nominal", "elevated", "high", "critical"}
                and natural(value["sensor_count"]))
    if name == "displays":
        return (all(natural(value[key]) for key in ("count", "internal_count", "external_count"))
                and isinstance(value["docked"], bool))
    if name == "devices":
        return all(natural(value[key], nullable=True) for key in value)
    if name == "connectivity":
        return value["state"] in {"connected", "local", "disconnected", "unknown"}
    if name == "media":
        return (value["state"] in {"playing", "paused", "idle"}
                and natural(value["player_count"]) and natural(value["playing_count"])
                and value["playing_count"] <= value["player_count"])
    if name == "time":
        return (value["band"] in {"night", "morning", "afternoon", "evening"}
                and isinstance(value["weekend"], bool)
                and isinstance(value["utc_offset_minutes"], int)
                and -1440 <= value["utc_offset_minutes"] <= 1440)
    if name == "operating_profile":
        return (value["selected"] in {"auto", "docked", "mobile", "unknown"}
                and value["active"] in {"docked", "mobile", "unknown"})
    return False


def sanitize(name, observation):
    if not isinstance(observation, dict) or not isinstance(observation.get("available"), bool):
        return result(False, reason="invalid-observation")
    if not observation["available"]:
        reason = observation.get("reason", "unavailable")
        return result(False, reason=reason if reason in REASON_CODES else "unavailable")
    value = observation.get("value")
    if not isinstance(value, dict) or set(value) != VALUE_KEYS[name] or not valid_value(name, value):
        return result(False, reason="privacy-schema-rejected")
    return result(True, value)


def fixture_observations(enabled):
    path = os.environ.get("MAGI_CONTEXT_FIXTURE")
    if not path:
        return None
    try:
        fixture = json.loads(Path(path).read_text())
    except (OSError, json.JSONDecodeError):
        return {name: result(False, reason="fixture-unavailable") for name in enabled}
    return {name: sanitize(name, fixture.get(name, {})) for name in enabled}


def collect_all(enabled):
    enabled = [name for name in enabled if name in COLLECTOR_FUNCTIONS]
    fixture = fixture_observations(enabled)
    if fixture is not None:
        return fixture
    observations = {}
    with ThreadPoolExecutor(max_workers=min(4, max(1, len(enabled)))) as executor:
        futures = {executor.submit(COLLECTOR_FUNCTIONS[name]): name for name in enabled}
        for future in as_completed(futures):
            name = futures[future]
            try:
                observations[name] = sanitize(name, future.result())
            except Exception:
                observations[name] = result(False, reason="collector-failed")
    return observations
