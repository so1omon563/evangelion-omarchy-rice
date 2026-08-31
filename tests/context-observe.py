#!/usr/bin/env python3
"""Optional privacy-safe T480 context timing; restores exact state on exit."""

import json
import os
import resource
import shutil
import statistics
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "test-results/context-observation.json"
COMMAND = shutil.which("magi-context")
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
CONTEXT_DIR = STATE_HOME / "evangelion-rice/context"
TRACKED = (CONTEXT_DIR / "state.json", CONTEXT_DIR / "requests.json",
           CONTEXT_DIR / "controller.lock")


def snapshot(path):
    if not path.exists():
        return None
    return {"bytes": path.read_bytes(), "mode": path.stat().st_mode & 0o777}


def restore(path, saved):
    if saved is None:
        path.unlink(missing_ok=True)
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.restore.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(saved["bytes"])
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, saved["mode"])
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def invoke(*args):
    started = time.perf_counter()
    result = subprocess.run([COMMAND, *args], text=True, capture_output=True, check=True)
    elapsed = (time.perf_counter() - started) * 1000
    return result, elapsed


def percentile(values, fraction):
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, int((len(ordered) - 1) * fraction))]


def main():
    if not COMMAND:
        raise SystemExit("magi-context is not installed")
    saved = {path: snapshot(path) for path in TRACKED}
    before_cpu = resource.getrusage(resource.RUSAGE_CHILDREN)
    timings = []
    idle_process_observations = 0
    idle_state_changes = 0
    try:
        for _ in range(12):
            result, elapsed = invoke("refresh", "--json", "--compact")
            json.loads(result.stdout)
            timings.append(elapsed)

        after_refresh_cpu = resource.getrusage(resource.RUSAGE_CHILDREN)

        idle_before = snapshot(CONTEXT_DIR / "state.json")
        for _ in range(60):
            probe = subprocess.run(["pgrep", "-x", "magi-context"], capture_output=True)
            idle_process_observations += probe.returncode == 0
            time.sleep(0.05)
        idle_after = snapshot(CONTEXT_DIR / "state.json")
        idle_state_changes = int(idle_before != idle_after)
    finally:
        for path, value in saved.items():
            restore(path, value)

    restored = all(snapshot(path) == value for path, value in saved.items())
    child_cpu_ms = ((after_refresh_cpu.ru_utime + after_refresh_cpu.ru_stime) -
                    (before_cpu.ru_utime + before_cpu.ru_stime)) * 1000
    report = {
        "schema_version": 1,
        "status": "passed" if restored and max(timings) < 2000 else "failed",
        "hardware_class": "ThinkPad T480 reference",
        "privacy": {"aggregate_metrics_only": True, "paths_or_identifiers": False},
        "refresh": {"samples": len(timings), "mean_ms": round(statistics.mean(timings), 2),
                    "p95_ms": round(percentile(timings, .95), 2),
                    "max_ms": round(max(timings), 2), "bound_ms": 2000,
                    "child_cpu_ms_total": round(child_cpu_ms, 2)},
        "idle": {"observation_ms": 3000, "sample_interval_ms": 50,
                 "context_process_observations": idle_process_observations,
                 "state_file_changes": idle_state_changes,
                 "controller_polling_expected": False},
        "restored": restored,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    if report["status"] != "passed":
        raise SystemExit("context observation failed its bound or restoration check")
    print(f"PASS  live context observation; p95={report['refresh']['p95_ms']}ms; state restored")
    print(f"RESULTS // {OUTPUT}")


if __name__ == "__main__":
    main()
