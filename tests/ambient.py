#!/usr/bin/env python3
"""Verify explicit, offline, reversible ambient projection."""

import importlib.machinery
import importlib.util
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        os.environ["HOME"] = str(home)
        os.environ["XDG_CONFIG_HOME"] = str(home / ".config")
        os.environ["XDG_STATE_HOME"] = str(home / ".local/state")
        loader = importlib.machinery.SourceFileLoader("magi_ambient", str(ROOT / "bin/magi-ambient"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        ambient = importlib.util.module_from_spec(spec); loader.exec_module(ambient)

        morning = ambient.projection(datetime(2026, 8, 31, 9, tzinfo=timezone.utc))
        assert morning["active"] and morning["band"] == "morning" and not morning["solar_configured"]
        assert not ambient.CACHE.exists(), "location-free ambient unexpectedly calculated solar data"

        ambient.STATE.mkdir(parents=True)
        (ambient.STATE / "mission-timer.json").write_text(json.dumps({"running": True, "paused": False, "phase": "work"}))
        (ambient.STATE / "at-field").mkdir(); (ambient.STATE / "at-field/active").touch()
        focused = ambient.projection(datetime(2026, 8, 31, 12, tzinfo=timezone.utc))
        assert focused["mission"] == "work" and focused["focus"] and focused["copy"] == "A.T. FIELD FOCUS"

        ambient.update(lambda value: value.update(location={"latitude": 33.4484, "longitude": -112.0740}))
        solar = ambient.projection(datetime(2026, 8, 31, 12, tzinfo=timezone.utc))
        assert solar["solar_configured"] and ambient.CACHE.exists()
        cached = ambient.CACHE.read_bytes()
        ambient.projection(datetime(2026, 8, 31, 13, tzinfo=timezone.utc))
        assert ambient.CACHE.read_bytes() == cached, "daily offline solar cache was not reused"

        ambient.update(lambda value: value.update(enabled=False))
        disabled = ambient.projection(datetime(2026, 8, 31, 12, tzinfo=timezone.utc))
        assert disabled["active"] is False and disabled["band"] == "baseline" and disabled["scene_offset"] == 0

    source = (ROOT / "bin/magi-ambient").read_text()
    assert all(word not in source for word in ("requests", "urllib", "geoclue", "curl"))
    screensaver = (ROOT / "bin/magi-screensaver").read_text()
    server = (ROOT / "start-page/server.py").read_text()
    assert '["magi-ambient", "status", "--json"]' in screensaver and '["magi-ambient", "status", "--json"]' in server
    assert "Timer" not in source and "while True" not in source
    print("PASS  explicit offline ambient time, mission, focus, quiet, and disable contracts")


if __name__ == "__main__": main()
