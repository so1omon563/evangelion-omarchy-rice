"""Shared bounded-retry and cache-freshness contract for optional surfaces."""
from __future__ import annotations

import json
import time
from pathlib import Path

DEFAULT = {
    "schema_version": 1,
    "request_timeout_seconds": 3,
    "retry_backoff_seconds": [15, 30, 60, 300],
    "surfaces": {
        "weather": {"fresh_seconds": 900, "stale_seconds": 21600},
        "context": {"fresh_seconds": 300, "stale_seconds": 1800},
        "updates": {"fresh_seconds": 900, "stale_seconds": 86400},
        "communications": {"fresh_seconds": 30, "stale_seconds": 300},
        "media": {"fresh_seconds": 15, "stale_seconds": 60},
        "artwork": {"fresh_seconds": 3600, "stale_seconds": 86400},
    },
    "privacy": {
        "remote_artwork_default": False,
        "persist_network_identifiers": False,
        "persist_media_metadata": False,
        "persist_context_payloads": False,
    },
}


def load_policy(path: Path | None = None) -> dict:
    path = path or Path.home() / ".config/omarchy/resilience.json"
    result = json.loads(json.dumps(DEFAULT))
    try:
        supplied = json.loads(path.read_text())
        if supplied.get("schema_version") == 1:
            result.update({k: supplied[k] for k in ("request_timeout_seconds", "retry_backoff_seconds") if k in supplied})
            result["surfaces"].update(supplied.get("surfaces", {}))
            result["privacy"].update(supplied.get("privacy", {}))
    except (OSError, ValueError, TypeError):
        pass
    return result


def cache_state(updated_at: int | float | None, limits: dict, now: int | float | None = None) -> dict:
    now = time.time() if now is None else now
    if not updated_at:
        return {"state": "unavailable", "age_seconds": None, "reason": "no-cached-data"}
    age = max(0, int(now - float(updated_at)))
    fresh = max(0, int(limits.get("fresh_seconds", 0)))
    stale = max(fresh, int(limits.get("stale_seconds", fresh)))
    if age <= fresh:
        state, reason = "fresh", "within-freshness-bound"
    elif age <= stale:
        state, reason = "stale", "provider-unavailable-using-cache"
    else:
        state, reason = "unavailable", "cache-expired"
    return {"state": state, "age_seconds": age, "reason": reason}


def retry_delay(failures: int, schedule: list[int]) -> int:
    values = [max(1, int(value)) for value in schedule] or [60]
    return values[min(max(0, failures - 1), len(values) - 1)]
