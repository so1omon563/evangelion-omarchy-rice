#!/usr/bin/env python3
"""Table-driven policy precedence, hysteresis, debounce, and cooldown tests."""

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "lib/magi_context_policy.py"
spec = importlib.util.spec_from_file_location("magi_context_policy", MODULE)
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)

SOURCES = set(policy.FACT_SOURCES.values())


def signals(fresh=True):
    return {name: {"availability": "available", "freshness": {"status": "fresh" if fresh else "stale"}}
            for name in SOURCES}


def evaluate(facts, previous=None, now=1000, fresh=True):
    return policy.evaluate(facts, signals(fresh), previous, now)


def main():
    precedence = [
        ({"temperature_c": 96, "power_source": "battery", "battery_percent": 5,
          "profile_selection": "mobile", "operating_profile": "mobile", "connectivity": "disconnected"}, "thermal-critical"),
        ({"temperature_c": 70, "power_source": "battery", "battery_percent": 5,
          "profile_selection": "mobile", "operating_profile": "mobile"}, "battery-critical"),
        ({"temperature_c": 70, "power_source": "ac", "battery_percent": 90,
          "profile_selection": "mobile", "operating_profile": "mobile", "connectivity": "disconnected"}, "manual-profile-selected"),
        ({"temperature_c": 76, "profile_selection": "mobile", "operating_profile": "mobile"}, "thermal-elevated"),
        ({"temperature_c": 70, "connectivity": "disconnected", "display_mode": "docked"}, "connectivity-offline"),
        ({"temperature_c": 76, "display_mode": "docked"}, "thermal-elevated"),
        ({"temperature_c": 70, "display_mode": "docked", "media_state": "playing"}, "environment-docked"),
        ({"temperature_c": 70, "media_state": "playing"}, "media-active"),
    ]
    for facts, expected in precedence:
        result = evaluate(facts)
        assert result["reason"]["code"] == expected, (facts, result)
        assert isinstance(result["reason"]["facts"], dict)
        assert result["automatic_actions"] == []

    thermal = evaluate({"temperature_c": 95})
    thermal = evaluate({"temperature_c": 92}, thermal)
    assert thermal["reason"]["code"] == "thermal-critical", "critical exit hysteresis failed"
    thermal = evaluate({"temperature_c": 89}, thermal)
    assert thermal["reason"]["code"] == "thermal-high"
    thermal = evaluate({"temperature_c": 79}, thermal)
    assert thermal["reason"]["code"] == "thermal-elevated"
    thermal = evaluate({"temperature_c": 69}, thermal)
    assert thermal["reason"]["code"] == "context-nominal"

    battery = evaluate({"power_source": "battery", "battery_percent": 7})
    battery = evaluate({"power_source": "battery", "battery_percent": 9}, battery)
    assert battery["reason"]["code"] == "battery-critical"
    battery = evaluate({"power_source": "battery", "battery_percent": 11}, battery)
    assert battery["reason"]["code"] == "battery-low"
    battery = evaluate({"power_source": "battery", "battery_percent": 21}, battery)
    assert battery["reason"]["code"] == "battery-conservation"
    battery = evaluate({"power_source": "battery", "battery_percent": 36}, battery)
    assert battery["reason"]["code"] == "context-nominal"

    mismatch = {"display_mode": "docked", "profile_selection": "auto", "operating_profile": "mobile"}
    first = evaluate(mismatch, now=1000)
    assert first["recommendations"] == []
    second = evaluate(mismatch, first, now=1001)
    assert second["recommendations"][0]["target"] == "docked"
    assert second["recommendations"][0]["requires_confirmation"] is True
    assert second["recommendations"][0]["newly_confirmed"] is True
    third = evaluate(mismatch, second, now=1002)
    assert third["recommendations"][0]["newly_confirmed"] is False, "confirmed recommendation was not stable"

    contradiction = evaluate({"display_mode": "mobile", "profile_selection": "auto", "operating_profile": "docked"}, second, now=1002)
    assert contradiction["recommendations"] == []
    assert contradiction["policy_state"]["candidates"]["profile-mismatch"] == {"target": "mobile", "count": 1, "confirmed": False}
    cooldown = evaluate({"display_mode": "mobile", "profile_selection": "auto", "operating_profile": "docked"}, contradiction, now=1003)
    assert cooldown["recommendations"] == [], "contradictory target bypassed recommendation cooldown"
    confirmed = evaluate({"display_mode": "mobile", "profile_selection": "auto", "operating_profile": "docked"}, cooldown, now=1302)
    assert confirmed["recommendations"][0]["newly_confirmed"] is True
    converged = evaluate({"display_mode": "mobile", "profile_selection": "auto", "operating_profile": "mobile"}, confirmed, now=1303)
    assert converged["policy_state"]["candidates"]["profile-mismatch"] == {"target": None, "count": 0, "confirmed": False}

    stale = evaluate({"temperature_c": 99, "display_mode": "docked"}, fresh=False)
    assert stale["status"] == "unknown" and stale["reason"]["code"] == "no-fresh-policy-inputs"

    print("PASS  deterministic MAGI context policy boundaries and convergence")


if __name__ == "__main__":
    main()
