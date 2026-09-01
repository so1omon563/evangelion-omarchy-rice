#!/usr/bin/env python3
"""Validate the prepared official Omarchy gallery submission."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
directory = ROOT / "packaging/gallery"
data = json.loads((directory / "submission.json").read_text())
preview = directory / "evangelion.webp"
submission = (directory / "SUBMISSION.md").read_text()

assert data["schema_version"] == 1
assert data["target_repository"] == "https://github.com/omacom/omarchy-site"
assert data["theme_repository"] == "https://github.com/so1omon563/omarchy-evangelion-theme"
assert data["theme_repository_commit"] == "c117a3ca6d2ecb07a3cd13f5a2e1e075c751b06a"
assert data["public_install"] == "passed-isolated-omarchy-theme-install"
assert data["insert_after"] == "Eldritch" and data["insert_before"] == "Event Horizon"
assert data["external_pull_request_allowed"] is False
assert preview.stat().st_size <= data["image_max_bytes"]
payload = preview.read_bytes()
assert payload[:4] == b"RIFF" and payload[8:12] == b"WEBP"
marker = payload.find(b"\x9d\x01\x2a")
assert marker >= 0, "expected lossy VP8 dimensions"
width, height = struct.unpack("<HH", payload[marker + 3:marker + 7])
assert (width & 0x3FFF, height & 0x3FFF) == (data["image_width"], data["image_height"])
assert hashlib.sha256(payload).hexdigest() == data["image_sha256"]
assert data["source_sha256"] != "PENDING"
assert "Do not open the pull request" in submission
assert 'assets/themes/evangelion.webp' in submission
assert 'alt="Evangelion theme"' in submission
assert "unofficial non-commercial fan theme" in submission

print("PASS  official Omarchy gallery submission package")
