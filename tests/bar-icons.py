#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
plugins = root / "omarchy/plugins"
shell = json.loads((root / "omarchy/shell.json").read_text())
frame = (plugins / "evangelion.icon-theme/UpstreamIconFrame.qml").read_text()
docs = (root / "BAR_ICONS.md").read_text()
bar_theme = (root / "theme/shell.bar.toml").read_text()

adapters = {
    "evangelion.agents": ("omarchy.agents", "/shell/plugins/agents/Panel.qml"),
    "evangelion.bluetooth": ("omarchy.bluetooth", "/shell/plugins/panels/bluetooth/Panel.qml"),
    "evangelion.dropbox": ("omarchy.dropbox", "/shell/plugins/panels/dropbox/Panel.qml"),
    "evangelion.tailscale": ("omarchy.tailscale", "/shell/plugins/panels/tailscale/Panel.qml"),
}

right = [entry["id"] for entry in shell["bar"]["layout"]["right"]]
assert "omarchy.tray" in right
assert all(adapter in right for adapter in adapters)
assert all(native not in right for native, _ in adapters.values())
assert any(item["id"] == "evangelion.icon-theme" for item in shell["plugins"])

for adapter, (native, source_path) in adapters.items():
    directory = plugins / adapter
    manifest = json.loads((directory / "manifest.json").read_text())
    source = (directory / "BarWidget.qml").read_text()
    assert manifest["id"] == adapter
    assert 'import "../evangelion.icon-theme" as Eva' in source
    assert f'upstreamModule: "{native}"' in source
    assert f'upstreamSource: "{source_path}"' in source
    assert adapter in docs and native in docs

for contract in (
    'Quickshell.env("OMARCHY_PATH")',
    'nativeItem.bar = root.bar',
    'nativeItem.settings = root.settings',
    'nativeItem.moduleName = root.upstreamModule',
    'typeof nativeItem.open === "function"',
    'typeof nativeItem.close === "function"',
    'typeof nativeItem.toggle === "function"',
    'implicitWidth: Math.max',
):
    assert contract in frame, contract

for forbidden_chrome in ("Rectangle {", "HoverHandler", "border.color", "stateColor"):
    assert forbidden_chrome not in frame, forbidden_chrome

assert 'text             = "#B79ACB"' in bar_theme

for forbidden in ("/home/", "so1omon", "Screen.name"):
    assert forbidden not in frame

assert "full-color" in docs
assert "Symbolic icons" in docs
assert "#B79ACB" in docs
assert "no per-widget frames" in docs
assert "fallback" in docs.lower()

print("bar icon unification contracts passed")
