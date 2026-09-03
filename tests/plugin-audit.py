#!/usr/bin/env python3
"""Verify the complete SO1-384 plugin inventory and classifications."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
plugin_root = ROOT / "omarchy/plugins"
audit = json.loads((ROOT / "plugin-audit.json").read_text())
guide = (ROOT / "PLUGIN_AUDIT.md").read_text()
rows = audit["plugins"]
by_id = {row["id"]: row for row in rows}
directories = {path.name for path in plugin_root.iterdir() if path.is_dir()}

assert audit["schema_version"] == 1
assert audit["baseline"] == "v1.5-development"
assert audit["standalone_support_claimed"] is False
assert len(rows) == len(by_id) == len(directories) == 37
assert set(by_id) == directories
assert audit["recommended_candidates"] == ["evangelion.cava", "evangelion.media"]
allowed = {"standalone", "optionally-integrated", "suite-only", "compatibility-only"}
assert all(row["classification"] in allowed for row in rows)
assert not any(row["classification"] == "standalone" for row in rows)

for plugin_id, row in by_id.items():
    directory = plugin_root / plugin_id
    manifest_path = directory / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    assert manifest["id"] == plugin_id
    assert row["entry"] in manifest["entryPoints"].values()
    assert (directory / row["entry"]).is_file()
    source = "\n".join(path.read_text(errors="ignore") for path in directory.rglob("*") if path.is_file())
    imports = sorted(set(re.findall(r'import "\.\./([^\"]+)"', source)) & directories)
    assert imports == sorted(row["shared_plugins"]), (plugin_id, imports, row["shared_plugins"])

ranked = sorted((row["candidate_rank"], row["id"]) for row in rows if row["candidate_rank"] is not None)
assert [plugin_id for _, plugin_id in ranked[:2]] == audit["recommended_candidates"]
for phrase in ("Dependency findings", "First marketplace candidates", "local-only empty", "no independently versioned protocol"):
    assert phrase in guide

print("PASS  complete MAGI plugin dependency and viability audit")
