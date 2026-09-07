#!/usr/bin/env python3
"""Offline, stale-cache, bounded-retry, privacy, and surface UI contracts."""
import importlib.util
import json
import os
import subprocess
import tempfile
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("magi_resilience", ROOT / "lib/magi_resilience.py")
MODULE = importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(MODULE)

limits = {"fresh_seconds": 10, "stale_seconds": 30}
assert MODULE.cache_state(None, limits, 100)["state"] == "unavailable"
assert MODULE.cache_state(95, limits, 100) == {"state":"fresh","age_seconds":5,"reason":"within-freshness-bound"}
assert MODULE.cache_state(80, limits, 100)["state"] == "stale"
assert MODULE.cache_state(60, limits, 100)["reason"] == "cache-expired"
assert [MODULE.retry_delay(x, [15, 30, 60]) for x in range(1, 6)] == [15, 30, 60, 60, 60]

policy = json.loads((ROOT / "omarchy/resilience.json").read_text())
assert policy["schema_version"] == 1 and 1 <= policy["request_timeout_seconds"] <= 5
assert policy["retry_backoff_seconds"] == sorted(policy["retry_backoff_seconds"])
assert set(policy["surfaces"]) >= {"weather","media","communications","context","updates","artwork"}
assert all(value is False for value in policy["privacy"].values())

with tempfile.TemporaryDirectory() as raw:
    home = Path(raw); config = home / ".config/omarchy"; config.mkdir(parents=True)
    (config / "resilience.json").write_text(json.dumps(policy))
    env = {**os.environ, "HOME": str(home)}
    report = json.loads(subprocess.run([str(ROOT/"bin/magi-resilience"), "--json"], env=env,
                                      text=True, capture_output=True, check=True).stdout)
    assert all(item["state"] == "unavailable" for item in report["surfaces"].values())
    assert report["privacy"]["remote_artwork_default"] is False

server_spec = importlib.util.spec_from_file_location("resilience_server", ROOT / "start-page/server.py")
server = importlib.util.module_from_spec(server_spec); server_spec.loader.exec_module(server)
with tempfile.TemporaryDirectory() as raw:
    cache = Path(raw) / "weather.json"
    cache.write_text(json.dumps({"message":"MESA · Temp 80°F · Wind calm", "updated_at":100}))
    with mock.patch.object(server, "WEATHER_CACHE", cache), mock.patch.object(server.time, "time", return_value=1001), mock.patch.object(server, "run", return_value=""):
        server.WEATHER_RETRY.update(failures=0, next_at=0)
        value = server.weather()
        assert value["state"] == "stale" and value["age_seconds"] == 901
        retry = value["retry_at"]
        server.weather()
        assert server.WEATHER_RETRY["next_at"] == retry

communications = (ROOT/"bin/magi-communications").read_text()
resilience_cli = (ROOT/"bin/magi-resilience").read_text()
start_js = (ROOT/"start-page/app.js").read_text()
update_qml = (ROOT/"omarchy/plugins/evangelion.update-operation/Service.qml").read_text()
assert 'timeout "${MAGI_PROVIDER_TIMEOUT_SECONDS:-3}s"' in communications
assert 'privacy:{persisted:false}' in communications
assert 'if not (LIB / "magi_resilience.py").is_file()' in resilience_cli
assert "AGE ${weather.age_seconds" in start_js and "RETRY BOUNDED" in start_js
assert 'property string freshness:"unavailable"' in update_qml and 'age<=86400?"stale"' in update_qml
print("PASS  bounded optional surfaces, cache age, privacy, and degraded visual states")
