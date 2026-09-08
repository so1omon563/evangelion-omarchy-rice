#!/usr/bin/env python3
"""Validate the exact v1.5 release decision and its durable evidence."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
gate = json.loads((ROOT / "release/v1.5.0.json").read_text())

assert gate["schema_version"] == 1
assert gate["release"] == "v1.5.0"
assert gate["candidate"] == "v1.5.0-rc.1"
assert gate["candidate_commit"] == "1b0d3f94781de6ea8f27a09cb393aa3439b2458f"
assert gate["final_release_allowed"] is True
assert gate["community_testing"] == {
    "status": "optional-post-release",
    "required_reports": 0,
}
assert gate["gates"]["candidate_ci"] == "passed-run-34179594611"
assert gate["gates"]["candidate_ci_duration"] == "16m0s"
assert gate["gates"]["validation"] == "passed-242-checks-zero-failures-zero-warnings"
assert gate["gates"]["candidate_artifact_sha256"] == (
    "3322d91ade9ee7871f2e9bad1a86694a5f4762976ccc7cfc0a055b64c516d564"
)

tagged = subprocess.check_output(
    ["git", "-C", str(ROOT), "rev-list", "-n", "1", gate["candidate"]], text=True
).strip()
assert tagged == gate["candidate_commit"]

assert gate["distribution"] == {
    "suite": "github-release-exact-tag",
    "theme": "standalone-export-synchronized",
    "plugins": "suite-internal-not-standalone",
    "optional_runtime": "contract-only-not-published",
}
assert gate["theme_repository_commit"] == "38b3d2599d78798a2face2495444334b774d2675"
assert set(gate["completed_children"]) == {
    "SO1-399", "SO1-408", "SO1-411", "SO1-413", "SO1-414",
    "SO1-415", "SO1-416", "SO1-417", "SO1-418",
}

notes = (ROOT / "RELEASE_NOTES.md").read_text()
upgrade = (ROOT / "UPGRADING.md").read_text()
artifacts = (ROOT / "RELEASE_ARTIFACTS.md").read_text()
maintaining = (ROOT / "MAINTAINING.md").read_text()
assert "v1.5.0 — Adaptive Operations" in notes
assert "Upgrade from v1.4.1 to v1.5" in upgrade
assert "evangelion-omarchy-rice-1.5.0.tar.gz" in artifacts
assert "wait for the exact candidate CI run to pass" in maintaining
assert "publish the archive and checksum" in maintaining

print("PASS  exact v1.5 candidate, distribution, migration, and artifact evidence")
