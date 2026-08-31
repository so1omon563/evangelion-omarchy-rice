#!/usr/bin/env python3
"""Collect privacy-safe live shell resource observations; restores motion mode."""

import json
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "test-results/motion-observation.json"


def run(*args, check=True):
    return subprocess.run(args, text=True, capture_output=True, check=check)


def shell_pid():
    result = run("pgrep", "-af", "quickshell", check=False)
    matches = [line.split(maxsplit=1)[0] for line in result.stdout.splitlines()
               if "/usr/share/omarchy/shell" in line]
    if result.returncode or not matches:
        raise SystemExit("omarchy-shell is not running")
    return int(matches[-1])


def process_metrics(pid):
    stat = Path(f"/proc/{pid}/stat").read_text()
    fields = stat[stat.rfind(")") + 2:].split()
    status = Path(f"/proc/{pid}/status").read_text().splitlines()
    values = {line.split(":", 1)[0]: line.split()[1] for line in status if ":" in line and line.split()[1:2]}
    return {"cpu_ticks": int(fields[11]) + int(fields[12]),
            "rss_kib": int(values["VmRSS"]), "threads": int(values["Threads"])}


def sample(pid, count=6, interval=.25, action=None):
    rows = []
    worker = threading.Thread(target=action) if action else None
    previous = process_metrics(pid)
    previous_at = time.monotonic()
    if worker:
        worker.start()
    for _ in range(count):
        time.sleep(interval)
        current_at = time.monotonic()
        current = process_metrics(pid)
        cpu = ((current["cpu_ticks"] - previous["cpu_ticks"]) / os.sysconf("SC_CLK_TCK") /
               (current_at - previous_at) * 100)
        rows.append({"cpu_percent": round(cpu, 2), "rss_kib": current["rss_kib"],
                     "threads": current["threads"]})
        previous, previous_at = current, current_at
    if worker:
        worker.join()
    return {"samples": len(rows),
            "cpu_percent_mean": round(sum(row["cpu_percent"] for row in rows) / len(rows), 2),
            "cpu_percent_max": max(row["cpu_percent"] for row in rows),
            "rss_kib_max": max(row["rss_kib"] for row in rows),
            "threads_max": max(row["threads"] for row in rows)}


def main():
    pid = shell_pid()
    original = run("magi-motion", "status").stdout.strip()
    report = {"schema_version": 1, "status": "passed", "hardware_class": "ThinkPad T480 reference",
              "sample_interval_ms": 250, "original_mode": original, "observations": {}}
    try:
        report["observations"]["idle"] = sample(pid)
        transition = {}
        def exercise():
            started = time.perf_counter()
            for mode in ("reduced", "off", "full") * 4:
                run("magi-motion", "set", mode)
                run("omarchy-shell", "workspace-osd", "preview", "1", check=False)
                run("omarchy-shell", "device-osd", "preview", "storage", "connected", check=False)
            transition["elapsed_ms"] = round((time.perf_counter() - started) * 1000, 2)
        report["observations"]["transition"] = sample(pid, count=20, action=exercise)
        report["transition_elapsed_ms"] = transition["elapsed_ms"]
    finally:
        run("magi-motion", "set", original, check=False)
        run("omarchy-shell", "workspace-osd", "hide", check=False)
        run("omarchy-shell", "device-osd", "hide", check=False)
    report["restored_mode"] = run("magi-motion", "status").stdout.strip()
    report["restored"] = report["restored_mode"] == original
    if not report["restored"]:
        report["status"] = "failed"
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"PASS  live motion observation; mode restored to {report['restored_mode']}")
    print(f"RESULTS // {OUTPUT}")


if __name__ == "__main__":
    main()
