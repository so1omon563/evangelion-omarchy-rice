#!/usr/bin/env python3
"""Validate the optional MAGI runtime distribution contract."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / "magi-runtime-contract.json").read_text())
docs = (root / "MAGI_RUNTIME.md").read_text()
distribution = (root / "DISTRIBUTION.md").read_text()
distribution_data = json.loads((root / "distribution.json").read_text())

assert contract["contract"] == "magi.optional-runtime"
assert contract["version"] == "1.0.0"
assert contract["decision"] == "intentionally-avoided-as-separate-package"
assert contract["distribution"]["package"] is None
assert contract["distribution"]["qml_library"] is None
assert contract["distribution"]["hidden_installation"] is False
assert contract["discovery"]["timeout_ms"] <= 250
assert contract["discovery"]["local_only"] is True
assert contract["discovery"]["read_only"] is True
assert contract["qml"]["public_cross_repository_import"] is False
assert contract["capabilities"]["motion"]["fallback"]["mode"] == "reduced"
assert contract["capabilities"]["motion"]["fallback"]["critical_feedback_ms"] == 0

states = set(contract["failure_states"])
assert states == {"absent", "compatible", "stale", "incompatible"}
tests = set(contract["compatibility_tests"])
for required in ("runtime-absent", "runtime-present-compatible",
                 "runtime-state-stale", "runtime-major-incompatible",
                 "runtime-schema-incompatible", "runtime-malformed",
                 "runtime-command-failure", "runtime-timeout"):
    assert required in tests

assert set(contract["first_candidates"]) == {"evangelion.cava", "evangelion.media"}
for candidate in contract["first_candidates"].values():
    assert candidate["required"]
    assert "magi.optional-runtime/motion" in candidate["optional"]

for phrase in ("no separately installed MAGI runtime package",
               "Required versus optional dependencies",
               "Failure and degradation semantics",
               "Compatibility matrix and release gate",
               "There are no public mutation commands"):
    assert phrase in docs
assert "MAGI_RUNTIME.md" in distribution
assert distribution_data["optional_runtime"]["version"] == contract["version"]
assert distribution_data["optional_runtime"]["plugin_local_fallbacks_required"] is True
assert distribution_data["optional_runtime"]["hidden_installation"] is False

print("PASS  optional MAGI runtime contract and compatibility matrix")
