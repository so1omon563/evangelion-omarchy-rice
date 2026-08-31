#!/usr/bin/env python3
import json
import re
import subprocess
import threading
import time
import tomllib
from collections import deque
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).parent
HOME = Path.home()
WEATHER_CACHE = HOME / ".cache/evangelion-rice/weather.json"
EVENTS = deque(maxlen=8)
EVENT_LOCK = threading.Lock()
PREVIOUS = {}
ACTIVE_PLAYER = ""


def run(args, timeout=2):
    try:
        return subprocess.run(args, text=True, capture_output=True, timeout=timeout).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def key_values(command):
    values = {}
    for line in run(command).splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def weather():
    message = run(["omarchy-weather-status"], 6)
    if message and message != "Weather unavailable":
        data = {"available": True, "message": message, "stale": False, "updated_at": int(time.time())}
        try:
            WEATHER_CACHE.parent.mkdir(parents=True, exist_ok=True)
            WEATHER_CACHE.write_text(json.dumps(data, separators=(",", ":")))
        except OSError:
            pass
        return data
    try:
        cached = json.loads(WEATHER_CACHE.read_text())
        if cached.get("message"):
            cached.update(available=True, stale=True)
            return cached
    except (OSError, json.JSONDecodeError):
        pass
    return {"available": False, "message": "Weather link unavailable", "stale": False}


def network():
    for interface in Path("/sys/class/net").iterdir():
        if interface.name == "lo":
            continue
        try:
            if (interface / "operstate").read_text().strip() == "up":
                return {"online": True, "interface": interface.name}
        except OSError:
            pass
    return {"online": False, "interface": "none"}


def workspace():
    names = {1: "MELCHIOR", 2: "BALTHASAR", 3: "CASPER", 4: "ENTRY PLUG", 5: "TERMINAL"}
    try:
        data = json.loads(run(["hyprctl", "-j", "activeworkspace"]))
        workspace_id = data.get("id", 0)
        return {"id": workspace_id, "name": names.get(workspace_id, data.get("name", "UNKNOWN"))}
    except json.JSONDecodeError:
        return {"id": 0, "name": "UNKNOWN"}


def media():
    selector = ["-p", ACTIVE_PLAYER] if ACTIVE_PLAYER else []
    fields = run(["playerctl", *selector, "metadata", "--format", "{{status}}\t{{artist}}\t{{title}}\t{{mpris:length}}\t{{playerName}}\t{{xesam:url}}"]).split("\t")
    try:
        position = max(0, float(run(["playerctl", *selector, "position"])))
    except ValueError:
        position = 0
    try:
        length = max(0, float(fields[3]) / 1_000_000)
    except (ValueError, IndexError):
        length = 0
    try:
        volume = max(0, min(1, float(run(["playerctl", *selector, "volume"]))))
    except ValueError:
        volume = 0
    players = [item for item in run(["playerctl", "-l"]).splitlines() if item]
    return {
        "available": len(fields) >= 3,
        "status": fields[0][:16] if fields else "",
        "artist": fields[1][:80] if len(fields) > 1 else "",
        "title": fields[2][:120] if len(fields) > 2 else "",
        "length": round(length, 1),
        "position": round(position, 1),
        "player": fields[4][:30] if len(fields) > 4 else "",
        "volume": round(volume * 100),
        "players": players[:12],
    }


def record_events(snapshot):
    checks = {
        "workspace": (snapshot["workspace"]["name"], "WORKSPACE", lambda value: f"CHANNEL {value.upper()} ACTIVE"),
        "affinity": (snapshot["affinity"]["active"], "AFFINITY", lambda value: f"{value.upper()} COLOR LINK"),
        "profile": (snapshot["profile"], "PROFILE", lambda value: f"{value.upper()} OPERATING PROFILE"),
        "network": (snapshot["network"]["online"], "NETWORK", lambda value: "UPLINK RESTORED" if value else "UPLINK LOST"),
        "thermal": (snapshot["thermal"].get("tier", "unknown"), "THERMAL", lambda value: f"THERMAL STATE {value.upper()}"),
        "media": (snapshot["media"]["status"], "MEDIA", lambda value: f"PLAYBACK {value.upper() or 'STANDBY'}"),
    }
    now = time.strftime("%H:%M:%S")
    with EVENT_LOCK:
        if not EVENTS:
            EVENTS.appendleft({"time": now, "type": "SYSTEM", "message": "MAGI DASHBOARD LINK ESTABLISHED"})
        for key, (value, event_type, message) in checks.items():
            if key in PREVIOUS and PREVIOUS[key] != value:
                EVENTS.appendleft({"time": now, "type": event_type, "message": message(value)})
            PREVIOUS[key] = value
        return list(EVENTS)


def status():
    try:
        colors = tomllib.loads((HOME / ".local/state/omarchy/current/theme/colors.toml").read_text())
    except (OSError, tomllib.TOMLDecodeError):
        colors = {}
    try:
        thermal = json.loads(run(["magi-thermal-alert", "status"]))
    except json.JSONDecodeError:
        thermal = {"available": False}
    capacities = []
    for path in Path("/sys/class/power_supply").glob("BAT*/capacity"):
        try:
            capacities.append(int(path.read_text()))
        except (OSError, ValueError):
            pass
    affinity = key_values(["magi-affinity", "status"])
    profile = key_values(["magi-operating-profile", "status"])
    snapshot = {
        "theme": {key: colors.get(key) for key in ("accent", "selection", "background", "dark_background", "foreground", "dark_foreground", "orange", "cyan", "bright_red") if colors.get(key)},
        "thermal": {key: thermal.get(key) for key in ("available", "temperature_c", "tier")},
        "battery": round(sum(capacities) / len(capacities)) if capacities else None,
        "network": network(),
        "media": media(),
        "weather": weather(),
        "workspace": workspace(),
        "affinity": {"mode": affinity.get("mode", "unknown"), "active": affinity.get("active", "neutral")},
        "profile": profile.get("active", profile.get("effective", "unknown")),
        "uptime": round(float(Path("/proc/uptime").read_text().split()[0])),
    }
    snapshot["events"] = record_events(snapshot)
    return snapshot


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, *args):
        pass

    def json_response(self, payload, code=200):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/api/status":
            self.json_response(status())
        else:
            super().do_GET()

    def do_POST(self):
        global ACTIVE_PLAYER
        if self.headers.get("Origin", "http://127.0.0.1:8765") != "http://127.0.0.1:8765":
            self.json_response({"ok": False}, 403)
            return
        actions = {
            "/api/media/previous": "previous",
            "/api/media/toggle": "play-pause",
            "/api/media/next": "next",
        }
        if self.path in actions:
            selector = ["-p", ACTIVE_PLAYER] if ACTIVE_PLAYER else []
            result = subprocess.run(["playerctl", *selector, actions[self.path]], capture_output=True, timeout=2)
            self.json_response({"ok": result.returncode == 0})
            return
        if self.path == "/api/media/player":
            try:
                length = min(1024, int(self.headers.get("Content-Length", "0")))
                player = json.loads(self.rfile.read(length)).get("player", "")
            except (ValueError, json.JSONDecodeError):
                player = ""
            available = run(["playerctl", "-l"]).splitlines()
            if player not in available or not re.fullmatch(r"[\w.-]+", player):
                self.json_response({"ok": False}, 400)
                return
            ACTIVE_PLAYER = player
            self.json_response({"ok": True, "player": player})
            return
        self.json_response({"ok": False}, 404)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
