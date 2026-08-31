#!/usr/bin/env python3
"""Validate v1.3 documentation, synthetic demo, and release privacy contracts."""

import hashlib
import json
import struct
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def text(path):
    return (ROOT / path).read_text()


def png_dimensions(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    assert data[12:16] == b"IHDR"
    return struct.unpack(">II", data[16:24])


def main():
    context = text("CONTEXT.md")
    release_notes = text("RELEASE_NOTES.md")
    upgrading = text("UPGRADING.md")
    troubleshooting = text("TROUBLESHOOTING.md")
    media_notes = text("media/README.md")
    readme = text("README.md")

    topics = {
        "inputs": "Inputs and privacy boundary",
        "derived states": "Derived states, reasons, and precedence",
        "recommendations": "Recommendations and automation",
        "accessibility": "Surfaces and accessibility",
        "performance": "Performance contract",
        "troubleshooting": "Troubleshooting",
        "privacy": "Clipboard data, browser history",
        "precedence": "Policy v1 evaluates fresh normalized facts in this order",
        "double opt-in": "requires both opt-ins",
        "no polling": "no resident context daemon or background polling loop",
    }
    for name, marker in topics.items():
        assert marker in context, f"v1.3 context documentation missing {name}"

    for marker in ("Upgrade from v1.2 to v1.3", "snapshot=$(cat", './rollback.sh "$snapshot"',
                   "without silently opting into automation"):
        assert marker in upgrading, marker
    for marker in ("MAGI context and recommendations", "manual-profile-selection",
                   "magi-context disable", "context-observe.py"):
        assert marker in troubleshooting, marker
    for marker in ("v1.3.0 — MAGI intelligence and context", "167.59 ms p95",
                   "External hardware feedback remains welcome but optional"):
        assert marker in release_notes, marker
    assert "[CONTEXT.md](CONTEXT.md)" in readme
    assert "media/context-states.png" in readme

    svg_path = ROOT / "media/context-states.svg"
    png_path = ROOT / "media/context-states.png"
    tree = ET.parse(svg_path)
    root = tree.getroot()
    assert root.attrib["width"] == "1600" and root.attrib["height"] == "720"
    svg = svg_path.read_text()
    for marker in ("RECOMMEND", "AUTOMATION", "STALE / MISSING", "DISABLED",
                   "NO LIVE TELEMETRY", "NO ACTION", "USER AUTHORITY"):
        assert marker in svg
    assert png_dimensions(png_path) == (1600, 720)

    hashes = {}
    for line in text("media/release-media.sha256").splitlines():
        digest, filename = line.split(maxsplit=1)
        hashes[filename] = digest
    for filename in ("context-states.svg", "context-states.png"):
        actual = hashlib.sha256((ROOT / "media" / filename).read_bytes()).hexdigest()
        assert hashes[filename] == actual
        assert filename in media_notes

    forbidden = ("/home/", "so1omon", "198.51.100", "PRIVATE_", "hostname", "account name")
    for value in forbidden:
        assert value not in svg
    assert "deterministically" in media_notes and "no profile" in media_notes

    manifest = ROOT / "release/v1.3.0.json"
    if manifest.exists():
        gate = json.loads(manifest.read_text())
        assert gate["release"] == "v1.3.0"
        assert gate["candidate"] == "v1.3.0-rc.1"
        assert gate["candidate_commit"] == "d363835424b48989a0e16c8869672a9df56fe6fe"
        assert gate["final_release_allowed"] is True
        assert gate["gates"]["candidate_ci"] == "passed-run-33450358582"
        assert gate["gates"]["context_regressions"].startswith("passed-")
        assert gate["gates"]["context_performance"].startswith("passed-t480-")
        assert gate["community_testing"]["status"] == "optional-post-release"
        assert gate["community_testing"]["required_reports"] == 0

    print("PASS  v1.3 documentation, demo, provenance, and release contracts")


if __name__ == "__main__":
    main()
