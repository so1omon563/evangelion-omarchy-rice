"""Pure, deterministic policy for normalized MAGI context facts."""

from copy import deepcopy

POLICY_VERSION = 1
PROFILE_DEBOUNCE_SAMPLES = 2
RECOMMENDATION_COOLDOWN_SECONDS = 300

FACT_SOURCES = {
    "power_source": "power", "battery_percent": "power",
    "thermal_pressure": "thermal", "temperature_c": "thermal",
    "display_mode": "displays", "device_counts": "devices",
    "connectivity": "connectivity", "media_state": "media",
    "time_band": "time", "weekend": "time",
    "operating_profile": "operating_profile",
    "profile_selection": "operating_profile",
}


def fresh_facts(facts, signals):
    """Exclude unavailable, disabled, unknown, and stale inputs from policy."""
    return {
        key: deepcopy(value) for key, value in facts.items()
        if signals.get(FACT_SOURCES.get(key, ""), {}).get("availability") == "available"
        and signals.get(FACT_SOURCES.get(key, ""), {}).get("freshness", {}).get("status") == "fresh"
    }


def thermal_band(temperature, previous="nominal"):
    if temperature is None:
        return None
    if temperature >= 95 or previous == "critical" and temperature >= 90:
        return "critical"
    if temperature >= 85 or previous in {"critical", "high"} and temperature >= 80:
        return "high"
    if temperature >= 75 or previous in {"critical", "high", "elevated"} and temperature >= 70:
        return "elevated"
    return "nominal"


def battery_band(percent, source, previous="normal"):
    if percent is None or source != "battery":
        return "normal"
    if percent <= 7 or previous == "critical" and percent <= 10:
        return "critical"
    if percent <= 15 or previous in {"critical", "low"} and percent <= 20:
        return "low"
    if percent <= 30 or previous in {"critical", "low", "conserve"} and percent <= 35:
        return "conserve"
    return "normal"


def candidate(priority, status, code, summary, facts, signals):
    return {"priority": priority, "status": status, "code": code,
            "summary": summary, "facts": facts, "signals": signals}


def select_state(facts, memory):
    thermal = thermal_band(facts.get("temperature_c"), memory.get("thresholds", {}).get("thermal", "nominal"))
    battery = battery_band(facts.get("battery_percent"), facts.get("power_source"),
                           memory.get("thresholds", {}).get("battery", "normal"))
    choices = []
    if thermal == "critical":
        choices.append(candidate(100, "critical", "thermal-critical", "Critical thermal pressure", {"temperature_c": facts["temperature_c"]}, ["thermal"]))
    if battery == "critical":
        choices.append(candidate(95, "critical", "battery-critical", "Critical internal power reserve", {"battery_percent": facts["battery_percent"]}, ["power"]))
    if thermal == "high":
        choices.append(candidate(90, "constrained", "thermal-high", "High thermal pressure", {"temperature_c": facts["temperature_c"]}, ["thermal"]))
    if battery == "low":
        choices.append(candidate(85, "constrained", "battery-low", "Low internal power reserve", {"battery_percent": facts["battery_percent"]}, ["power"]))

    selection = facts.get("profile_selection")
    active = facts.get("operating_profile")
    if thermal == "elevated":
        choices.append(candidate(84, "constrained", "thermal-elevated", "Elevated thermal pressure",
                                 {"temperature_c": facts["temperature_c"]}, ["thermal"]))
    if battery == "conserve":
        choices.append(candidate(82, "constrained", "battery-conservation", "Internal power conservation advised",
                                 {"battery_percent": facts["battery_percent"]}, ["power"]))
    if selection in {"docked", "mobile"}:
        choices.append(candidate(80, "manual", "manual-profile-selected", f"Manual {selection} profile is authoritative",
                                 {"profile_selection": selection, "operating_profile": active}, ["operating_profile"]))
    if facts.get("connectivity") == "disconnected":
        choices.append(candidate(70, "offline", "connectivity-offline", "Communication link is offline",
                                 {"connectivity": "disconnected"}, ["connectivity"]))
    if facts.get("display_mode") in {"docked", "mobile"}:
        mode = facts["display_mode"]
        choices.append(candidate(20, mode, f"environment-{mode}", f"{mode.title()} environment observed",
                                 {"display_mode": mode}, ["displays"]))
    if facts.get("media_state") == "playing":
        choices.append(candidate(10, "media-active", "media-active", "Media playback is active",
                                 {"media_state": "playing"}, ["media"]))
    choices.append(candidate(0, "nominal", "context-nominal", "No exceptional operating context detected", {}, []))
    choices.sort(key=lambda item: (-item["priority"], item["code"]))
    return choices[0], choices[1:], {"thermal": thermal or "unknown", "battery": battery}


def profile_recommendations(facts, memory, now):
    candidates = deepcopy(memory.get("candidates", {})) if isinstance(memory.get("candidates"), dict) else {}
    cooldowns = deepcopy(memory.get("cooldowns", {})) if isinstance(memory.get("cooldowns"), dict) else {}
    target = facts.get("display_mode")
    selected = facts.get("profile_selection")
    active = facts.get("operating_profile")
    mismatch = target if selected == "auto" and target in {"docked", "mobile"} and active in {"docked", "mobile"} and active != target else None
    prior = candidates.get("profile-mismatch", {})
    prior_count = prior.get("count", 0) if isinstance(prior, dict) else 0
    prior_count = prior_count if isinstance(prior_count, int) and prior_count >= 0 else 0
    same_target = bool(mismatch and isinstance(prior, dict) and prior.get("target") == mismatch)
    count = min(prior_count + 1, 1000000) if same_target else 1 if mismatch else 0
    confirmed = bool(same_target and prior.get("confirmed") is True)
    recommendations = []
    last = cooldowns.get("profile-switch", 0)
    last = last if isinstance(last, (int, float)) and 0 <= last <= now else 0
    newly_confirmed = bool(mismatch and not confirmed and count >= PROFILE_DEBOUNCE_SAMPLES
                           and now - last >= RECOMMENDATION_COOLDOWN_SECONDS)
    if newly_confirmed:
        confirmed = True
        cooldowns["profile-switch"] = now
    candidates["profile-mismatch"] = {"target": mismatch, "count": count, "confirmed": confirmed}
    if mismatch and confirmed:
        recommendations.append({
            "id": f"profile-switch-{mismatch}", "action": "select-operating-profile",
            "target": mismatch, "reason_code": "profile-environment-mismatch",
            "summary": f"Consider switching the operating profile to {mismatch}",
            "contributing_facts": {"display_mode": mismatch, "operating_profile": active},
            "requires_confirmation": True, "newly_confirmed": newly_confirmed,
        })
    return recommendations, candidates, cooldowns


def evaluate(facts, signals, previous=None, now=0):
    """Return policy output. No action is ever executed by this module."""
    previous_memory = (previous or {}).get("policy_state", {})
    previous_memory = previous_memory if isinstance(previous_memory, dict) else {}
    usable = fresh_facts(facts, signals)
    if usable:
        primary, suppressed, thresholds = select_state(usable, previous_memory)
    else:
        primary = candidate(0, "unknown", "no-fresh-policy-inputs", "No fresh inputs are available for policy evaluation", {}, [])
        suppressed, thresholds = [], {"thermal": "unknown", "battery": "normal"}
    recommendations, candidates, cooldowns = profile_recommendations(usable, previous_memory, now)
    reason = {"code": primary["code"], "summary": primary["summary"],
              "signals": primary["signals"], "facts": primary["facts"]}
    memory = {"version": POLICY_VERSION, "thresholds": thresholds,
              "candidates": candidates, "cooldowns": cooldowns,
              "suppressed_reason_codes": [item["code"] for item in suppressed if item["priority"] > 0]}
    return {
        "status": primary["status"], "summary": primary["summary"],
        "reason": reason, "recommendations": recommendations,
        "automatic_actions": [], "policy_state": memory,
    }
