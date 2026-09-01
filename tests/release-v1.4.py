#!/usr/bin/env python3
"""Validate the exact v1.4 distribution release decision and public evidence."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]

gate = json.loads((ROOT / "release/v1.4.0.json").read_text())
assert gate["schema_version"] == 1
assert gate["release"] == "v1.4.0"
assert gate["candidate"] == "v1.4.0-rc.1"
assert gate["candidate_commit"] == "2410a7643a48df5e663c61b2bad304028cad91bf"
assert gate["final_release_allowed"] is True
assert gate["gates"]["candidate_ci"] == "passed-run-33468175175"
assert gate["community_testing"]["status"] == "optional-post-release"
assert gate["community_testing"]["required_reports"] == 0

tagged = subprocess.check_output(
    ["git", "-C", str(ROOT), "rev-list", "-n", "1", gate["candidate"]], text=True
).strip()
assert tagged == gate["candidate_commit"]

distribution = gate["distribution"]
assert distribution["plugins"] == "suite-internal-not-standalone"
assert distribution["optional_runtime"] == "contract-only-not-published"
assert distribution["suite"] == "github-release-exact-tag"

notes = (ROOT / "RELEASE_NOTES.md").read_text()
guide = (ROOT / "DISTRIBUTION_GUIDE.md").read_text()
maintaining = (ROOT / "MAINTAINING.md").read_text()
for marker in ("v1.4.0 — distribution and packaging", "suite-internal", "machine-readable"):
    assert marker in notes
for marker in ("Just the look", "Complete MAGI desktop", "Managed Arch package", "Switching channels"):
    assert marker in guide
for marker in ("Final release checklist", "Theme gallery review", "wait for the exact candidate CI"):
    assert marker in maintaining

for row in (ROOT / "media/release-media.sha256").read_text().splitlines():
    digest, filename = row.split(maxsplit=1)
    assert hashlib.sha256((ROOT / "media" / filename).read_bytes()).hexdigest() == digest

print("PASS  exact v1.4 candidate, distribution, documentation, and privacy evidence")
