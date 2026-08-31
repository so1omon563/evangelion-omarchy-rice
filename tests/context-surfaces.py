#!/usr/bin/env python3
"""Enforce the shared, reversible decorative-context contract."""

import importlib.util
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / "bin/magi-context"
SURFACES = {
    "mode OSD": ROOT / "omarchy/plugins/evangelion.mode-transition/Service.qml",
    "notifications": ROOT / "omarchy/plugins/evangelion.notifications/Service.qml",
    "start page": ROOT / "start-page/server.py",
    "screensaver": ROOT / "bin/magi-screensaver",
}


def main():
    for name, path in SURFACES.items():
        source = path.read_text()
        assert 'magi-context", "surface", "--json", "--compact"' in source or \
               '"magi-context","surface","--json","--compact"' in source, f"{name} bypasses shared projection"
        projection_area = source[source.find("magi-context") - 800:source.find("magi-context") + 300]
        assert "nmcli" not in projection_area and "/sys/class/power_supply" not in projection_area, f"{name} context adapter duplicates detection"

    card = (ROOT / "omarchy/plugins/evangelion.notifications/components/NotificationCard.qml").read_text()
    assert "contextSurface.active" in card and "urgency === 0" in card
    osd = SURFACES["mode OSD"].read_text()
    assert "width:Math.min(440,parent.width-32); height:104" in osd
    html = (ROOT / "start-page/index.html").read_text()
    css = (ROOT / "start-page/style.css").read_text()
    assert 'id="context-state" hidden' in html and ".status-rail [hidden]{display:none}" in css

    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary)
        env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
               "XDG_STATE_HOME": str(home / ".local/state")}
        value = json.loads(subprocess.run([str(COMMAND), "surface", "--json", "--compact"],
                                          env=env, text=True, capture_output=True, check=True).stdout)
        assert value["active"] is False and value["status"] == "baseline" and value["facts"] == {}

    spec = importlib.util.spec_from_file_location("start_page_server", ROOT / "start-page/server.py")
    server = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(server)
    original = server.run
    server.run = lambda _args, _timeout=2: ""
    try:
        assert server.context_surface()["active"] is False
        assert server.context_surface()["status"] == "baseline"
    finally:
        server.run = original

    print("PASS  shared context projection and reversible visual surfaces")


if __name__ == "__main__":
    main()
