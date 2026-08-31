#!/usr/bin/env python3
"""Read-only compatibility preflight for Evangelion Omarchy Rice."""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HOME = Path.home()
SUPPORTED = {"omarchy": ((4, 0, 0), (5, 0, 0)), "hyprland": ((0, 56, 0), (0, 57, 0))}


def run(*command):
    try:
        return subprocess.run(command, text=True, capture_output=True, timeout=3, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None


def version_tuple(value):
    found = re.search(r"(\d+)\.(\d+)(?:\.(\d+))?", value or "")
    return tuple(map(int, (found.group(1), found.group(2), found.group(3) or 0))) if found else None


def package_version(name):
    result = run("pacman", "-Q", name)
    return result.stdout.strip().split(maxsplit=1)[1] if result and result.returncode == 0 else ""


def command_version(command, package):
    result = run(command, "version") if shutil.which(command) else None
    value = result.stdout.strip() if result and result.returncode == 0 else ""
    return value or package_version(package)


def writable_target(path):
    current = path
    while not current.exists() and current != current.parent:
        current = current.parent
    try:
        stat = current.stat()
    except OSError:
        return False
    mode = stat.st_mode
    if stat.st_uid == os.geteuid():
        return bool(mode & 0o200 and mode & 0o100)
    if stat.st_gid == os.getegid() or stat.st_gid in os.getgroups():
        return bool(mode & 0o020 and mode & 0o010)
    return bool(mode & 0o002 and mode & 0o001)


def port_open(port):
    wanted = f"{port:04X}"
    for table in (Path("/proc/net/tcp"), Path("/proc/net/tcp6")):
        try:
            rows = table.read_text().splitlines()[1:]
        except OSError:
            continue
        for row in rows:
            columns = row.split()
            if len(columns) > 3 and columns[1].rsplit(":", 1)[-1] == wanted and columns[3] == "0A":
                return True
    return False


def active_service(unit):
    result = run("systemctl", "--user", "is-active", unit)
    return bool(result and result.returncode == 0 and result.stdout.strip() == "active")


def monitors():
    result = run("hyprctl", "-j", "monitors")
    try:
        values = json.loads(result.stdout) if result and result.returncode == 0 else []
    except json.JSONDecodeError:
        values = []
    return [{"name": item.get("name"), "width": item.get("width"), "height": item.get("height"),
             "scale": item.get("scale"), "transform": item.get("transform")} for item in values]


def default_browser():
    result = run("xdg-settings", "get", "default-web-browser") if shutil.which("xdg-settings") else None
    return result.stdout.strip() if result and result.returncode == 0 else "unavailable"


def dependency_groups():
    groups = []
    for line in (ROOT / "dependencies.tsv").read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        level, feature, commands, packages, description = line.split("\t")
        missing = [item for item in commands.split(",") if not shutil.which(item)]
        groups.append({"level": level, "feature": feature, "status": "missing" if missing else "ready",
                       "missing": missing, "packages": packages.split(","), "description": description})
    return groups


def hotkey_report():
    text = (ROOT / "hypr" / "bindings.lua").read_text()
    keys = re.findall(r'o\.bind\("([^"]+)"', text)
    duplicates = sorted({key for key in keys if keys.count(key) > 1})
    live = HOME / ".config/hypr/bindings.lua"
    state = "same-as-repository" if live.exists() and live.read_bytes() == (ROOT / "hypr/bindings.lua").read_bytes() else "review-required"
    return {"declared": len(keys), "duplicates": duplicates, "live_target": state}


def add_check(checks, name, status, detail, remediation=""):
    checks.append({"name": name, "status": status, "detail": detail, "remediation": remediation})


def build_report(activation):
    checks = []
    omarchy = command_version("omarchy", "omarchy")
    hyprland = command_version("hyprctl", "hyprland")
    for name, value in (("omarchy", omarchy), ("hyprland", hyprland)):
        parsed = version_tuple(value)
        lower, upper = SUPPORTED[name]
        if not parsed:
            add_check(checks, f"{name}-version", "blocker", "not detected", f"Install {name} through Omarchy and rerun preflight")
        elif lower <= parsed < upper:
            add_check(checks, f"{name}-version", "pass", value, f"Supported range: >={'.'.join(map(str, lower))}, <{'.'.join(map(str, upper))}")
        else:
            add_check(checks, f"{name}-version", "blocker", value, f"Supported range: >={'.'.join(map(str, lower))}, <{'.'.join(map(str, upper))}")

    session_type = os.environ.get("XDG_SESSION_TYPE", "")
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    session_ready = session_type.lower() == "wayland" and "hyprland" in desktop.lower() and bool(signature)
    add_check(checks, "active-session", "pass" if session_ready or not activation else "blocker",
              f"type={session_type or 'unset'}, desktop={desktop or 'unset'}, hyprland_socket={'set' if signature else 'unset'}",
              "Run from an active Omarchy Hyprland session, or use --source-only when activation is not requested")

    deps = dependency_groups()
    for group in deps:
        if not group["missing"]:
            continue
        status = "blocker" if group["level"] == "required" else "optional"
        add_check(checks, f"dependency:{group['feature']}", status, "missing " + ", ".join(group["missing"]),
                  "omarchy pkg add " + " ".join(group["packages"]))

    targets = [HOME / ".config", HOME / ".local/bin", HOME / ".local/share", HOME / ".local/state"]
    unwritable = [str(path) for path in targets if not writable_target(path)]
    add_check(checks, "target-paths", "blocker" if unwritable else "pass",
              "unwritable: " + ", ".join(unwritable) if unwritable else "configuration, data, state, and binary targets are writable",
              "Correct ownership/permissions on the listed user paths")

    usage = shutil.disk_usage(HOME)
    required_bytes = max(100 * 1024 * 1024, sum(path.stat().st_size for path in ROOT.rglob("*") if path.is_file()) * 3)
    add_check(checks, "backup-space", "blocker" if usage.free < required_bytes else "pass",
              f"{usage.free // (1024*1024)} MiB free; {required_bytes // (1024*1024)} MiB safety minimum",
              "Free space in the home filesystem before installation")

    port = port_open(8765)
    expected_service = active_service("magi-start-page.service")
    add_check(checks, "start-page-port", "blocker" if port and not expected_service else "pass",
              "port 8765 is " + ("owned by the existing MAGI service" if port and expected_service else "occupied by another process" if port else "available"),
              "Stop the process using TCP port 8765 or configure a different port")
    incompatible_services = [unit for unit in ("waybar.service", "swaync.service") if active_service(unit)]
    add_check(checks, "service-conflicts", "blocker" if incompatible_services else "pass",
              "active competing services: " + ", ".join(incompatible_services) if incompatible_services else "no competing bar or notification services detected",
              "Disable the competing user service before activating the Omarchy shell")
    hotkeys = hotkey_report()
    hotkey_status = "blocker" if hotkeys["duplicates"] else "optional" if hotkeys["live_target"] == "review-required" else "pass"
    add_check(checks, "hotkeys", hotkey_status,
              f"{hotkeys['declared']} bindings; duplicates={hotkeys['duplicates'] or 'none'}; live={hotkeys['live_target']}",
              "Review ~/.config/hypr/bindings.lua before installation")

    monitor_data = monitors()
    add_check(checks, "display-ipc", "pass" if monitor_data else "optional",
              f"{len(monitor_data)} active monitor(s) reported" if monitor_data else "Hyprland display geometry unavailable to this process",
              "Run preflight directly inside the active Hyprland session for geometry and scale details")
    terminals = [name for name in ("ghostty", "alacritty", "foot", "kitty") if shutil.which(name)]
    batteries = sorted(path.name for path in Path("/sys/class/power_supply").glob("BAT*"))
    thermal = len(list(Path("/sys/class/thermal").glob("thermal_zone*")))
    audio = "pipewire" if shutil.which("wpctl") else "pulseaudio" if shutil.which("pactl") else "unavailable"
    network = sorted(path.name for path in Path("/sys/class/net").iterdir() if path.name != "lo") if Path("/sys/class/net").exists() else []
    capabilities = {
        "architecture": os.uname().machine,
        "session": {"type": session_type or "unknown", "desktop": desktop or "unknown", "activation_requested": activation},
        "display": monitor_data or [{"status": "unavailable outside a responsive Hyprland IPC connection"}],
        "terminals": terminals,
        "shell": os.environ.get("SHELL", "unknown"),
        "browser": default_browser(),
        "battery": batteries,
        "thermal_zones": thermal,
        "audio": audio,
        "network_interfaces": network,
        "hotkeys": hotkeys,
    }
    blockers = sum(item["status"] == "blocker" for item in checks)
    optional = sum(item["status"] == "optional" for item in checks)
    return {"schema_version": 1, "compatible": blockers == 0, "supported_ranges": {
        "omarchy": ">=4.0.0,<5.0.0", "hyprland": ">=0.56.0,<0.57.0"},
        "detected_versions": {"omarchy": omarchy or "unavailable", "hyprland": hyprland or "unavailable"},
        "checks": checks, "dependencies": deps, "capabilities": capabilities,
        "summary": {"blockers": blockers, "optional_gaps": optional}}


def human(report):
    print("MAGI COMPATIBILITY PREFLIGHT // READ-ONLY")
    print(f"Omarchy {report['detected_versions']['omarchy']} // Hyprland {report['detected_versions']['hyprland']}")
    for item in report["checks"]:
        marker = {"pass": "PASS", "optional": "WARN", "blocker": "FAIL"}[item["status"]]
        print(f"{marker:<5} {item['name']:<24} {item['detail']}")
        if item["status"] != "pass" and item["remediation"]:
            print(f"      REMEDIATION // {item['remediation']}")
    print("\nCAPABILITIES")
    for key, value in report["capabilities"].items():
        print(f"{key:<20} {json.dumps(value, separators=(',', ':')) if isinstance(value, (list, dict)) else value}")
    summary = report["summary"]
    print(f"\nSUMMARY // {summary['blockers']} blockers · {summary['optional_gaps']} optional gaps")
    print("READY // installation may proceed" if report["compatible"] else "BLOCKED // resolve failures before installation")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    parser.add_argument("--source-only", action="store_true", help="do not require an active Hyprland session")
    args = parser.parse_args()
    report = build_report(not args.source_only)
    print(json.dumps(report, indent=2, sort_keys=True) if args.json else human(report) or "")
    return 0 if report["compatible"] else 1


if __name__ == "__main__":
    sys.exit(main())
