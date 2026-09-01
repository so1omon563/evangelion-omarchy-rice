#!/usr/bin/env python3
"""Semantic desktop-state contracts for the local NERV start page."""
import importlib.util
import json
import os
import tempfile
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("start_page_server", ROOT / "start-page/server.py")
SERVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SERVER)

with tempfile.TemporaryDirectory() as directory:
    state = Path(directory)
    active = state / "affinity-active"
    refresh = state / "bar-refresh.json"
    active.write_text("unit-01\n")
    refresh.write_text(json.dumps({"result": "success"}))
    os.utime(refresh, (active.stat().st_mtime + 1, active.stat().st_mtime + 1))
    with mock.patch.object(SERVER, "AFFINITY_ACTIVE", active), mock.patch.object(SERVER, "BAR_REFRESH", refresh):
        with mock.patch.object(SERVER, "key_values", return_value={"mode": "auto", "active": "unit-01"}):
            assert SERVER.affinity_surface() == {"mode": "auto", "active": "unit-01", "label": "UNIT-01", "state": "current"}
        refresh.write_text(json.dumps({"result": "failed"}))
        with mock.patch.object(SERVER, "key_values", return_value={"mode": "manual", "active": "unit-00-refit"}):
            assert SERVER.affinity_surface()["state"] == "stale"
        with mock.patch.object(SERVER, "key_values", return_value={}):
            assert SERVER.affinity_surface()["state"] == "unavailable"
        with mock.patch.object(SERVER, "key_values", return_value={"mode": "disabled", "active": "neutral"}):
            assert SERVER.affinity_surface()["state"] == "disabled"

with mock.patch.object(SERVER, "run", return_value='{"id":4,"name":"4"}'):
    assert SERVER.workspace() == {"available": True, "id": 4, "label": "WORKSPACE-04 · ENTRY"}
with mock.patch.object(SERVER, "run", return_value=""):
    assert SERVER.workspace()["available"] is False

app = (ROOT / "start-page/app.js").read_text()
html = (ROOT / "start-page/index.html").read_text()
server = (ROOT / "start-page/server.py").read_text()
assert '"/api/desktop"' in server
assert '"magi-operating-profile", "status"' in server
assert "setInterval(syncDesktop, 2000)" in app
assert "rail-affinity-state" in app and 'id="rail-affinity-state"' in html
assert '"Cache-Control", "no-store, max-age=0"' in server
assert "if (affinityState)" in app and "if ($('rail-affinity-state'))" in app
assert 'style.css?v=' in html and 'app.js?v=' in html
assert "hyprctl" in server, "workspace IPC contract missing"
for forbidden in ("activewindow", "clients -j", "hostname", "address"):
    assert forbidden not in server.lower(), f"private desktop field leaked: {forbidden}"
print("PASS  start-page affinity freshness, workspace identity, fallback, and privacy contracts")
