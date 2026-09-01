#!/usr/bin/env python3
"""Validate the normative v1.4 distribution matrix."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
matrix = json.loads((ROOT / "distribution.json").read_text())
guide = (ROOT / "DISTRIBUTION.md").read_text()

assert matrix["schema_version"] == 1
assert matrix["baseline"] == "v1.3.1"
assert set(matrix["tiers"]) == {"theme", "suite", "arch"}
for name, tier in matrix["tiers"].items():
    for field in ("channel", "payload", "owns_user_config", "activation", "rollback", "removal", "versioning"):
        assert field in tier, f"{name} lacks {field}"
assert matrix["tiers"]["arch"]["owns_user_config"] is False
assert matrix["policies"]["silent_home_overwrite"] == "prohibited"
assert matrix["policies"]["system_install_mutates_home"] is False
assert matrix["policies"]["artwork_commercial_distribution"] is False
assert matrix["licenses"]["software_and_configuration"] == "MIT"
assert matrix["internal_plugins"] == {
    "distribution": "suite-only", "standalone_advertising": False,
    "standalone_installation": False, "runtime_publication": False}
assert matrix["channel_conflicts"]["theme-to-suite"]["policy"].startswith("refuse-")
for phrase in ("Distribution matrix", "Ownership boundaries", "Lifecycle contract",
               "Versions, dependencies, and compatibility", "Artwork, licensing, and catalogs"):
    assert phrase in guide

print("PASS  v1.4 distribution tiers and ownership contract")
