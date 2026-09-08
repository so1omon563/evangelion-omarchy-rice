#!/usr/bin/env python3
"""Verify the coherent v1.5 release-preparation and migration surface."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
assert (ROOT/"VERSION").read_text().strip()=="1.5.0"
assert json.loads((ROOT/"omarchy/rice-health.json").read_text())["suite_version"]=="1.5.0"
assert json.loads((ROOT/"packaging/theme/manifest.json").read_text())["derived_from_suite"]=="v1.5.0"
notes=(ROOT/"RELEASE_NOTES.md").read_text();assert "v1.5.0 — Adaptive Operations" in notes
for token in ("command palette","operations log","progressive telemetry disclosure","Work, Focus","OLED","quiet-hour","machine profiles","schema-v2","disabled by default","rollback"):
 assert token.lower() in notes.lower(),token
upgrade=(ROOT/"UPGRADING.md").read_text();assert "Upgrade from v1.4.1 to v1.5" in upgrade and "magi-migrate preview" in upgrade and "evangelion-omarchy-rice-1.5.0.tar.gz" in upgrade
migration=json.loads((ROOT/"migrations/1.4.1-to-1.5.0.json").read_text());preserved=set(migration["preserved"])
for name in ("resilience","sound","activity-modes","disclosure","operations-log","performance","topologies","media","workspaces","visual","scenes"):
 assert f"omarchy/{name}.json" in preserved,name
allow=set(line for line in (ROOT/"packaging/release/allowlist.txt").read_text().splitlines() if line and not line.startswith("#"))
for item in ("COMMAND_PALETTE.md","OPERATIONS_LOG.md","PROGRESSIVE_DISCLOSURE.md","ACTIVITY_MODES.md","THEME_VARIANTS.md","SOUND.md","OFFLINE_RESILIENCE.md","MACHINE_PROFILES.md","COMMUNITY_REPORT_TRIAGE.md","schemas/","compatibility/","tools/accept-compatibility-report"):
 assert item in allow,item
for path in ("README.md","RELEASE_ARTIFACTS.md","DISTRIBUTION_GUIDE.md","ARCH_PACKAGING.md","MAINTAINING.md"):
 text=(ROOT/path).read_text();assert "1.5.0" in text,path
print("PASS  coherent v1.5 version notes migration distribution and public artifact surface")
