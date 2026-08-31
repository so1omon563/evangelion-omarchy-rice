#!/usr/bin/env python3
"""Check that public documentation covers and matches the shipped interface."""

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def text(name):
    return (ROOT / name).read_text()


def main():
    readme = text("README.md")
    install = text("INSTALL.md")
    config = text("CONFIGURATION.md")
    trouble = text("TROUBLESHOOTING.md")
    upgrade = text("UPGRADING.md")

    for guide in ("INSTALL.md", "CONFIGURATION.md", "TROUBLESHOOTING.md", "UPGRADING.md",
                  "HOTKEYS.md", "RESPONSIVE.md", "TESTING.md", "ASSETS_LICENSE.md",
                  "BETA_TESTING.md", "RELEASE_NOTES.md"):
        assert f"]({guide})" in readme, f"README does not link {guide}"

    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if "://" in target or target.startswith("#"):
            continue
        path = ROOT / target.split("#", 1)[0]
        assert path.exists(), f"broken local README link: {target}"

    output = subprocess.run([str(ROOT / "install.sh"), "--list-components"],
                            text=True, capture_output=True, check=True).stdout
    components = {line.split()[0] for line in output.splitlines() if line.strip()}
    documented = set(re.findall(r"^\| `([a-z-]+)` \|", install, re.MULTILINE))
    assert components == documented, f"component table mismatch: {components ^ documented}"

    for phrase in (">=4.0.0, <5.0.0", ">=0.56.0, <0.57.0", "x86_64",
                   "ThinkPad T480", "Support covers", "1280×720", "320×480"):
        assert phrase in readme, f"support statement missing: {phrase}"
    for key in ("terminal", "editor", "browser", "project_dir", "shell", "weather",
                "operating-profiles.json", "Cava", "Neon"):
        assert key.lower() in config.lower(), f"configuration topic missing: {key}"
    for topic in ("Shell", "plugins", "Services", "Wallpaper", "Weather", "Media",
                  "Cava", "temperature", "Hotkey"):
        assert topic.lower() in trouble.lower(), f"troubleshooting topic missing: {topic}"
    for phrase in ("so1omon.*", "evangelion.*", "rollback", "uninstall", "newest to oldest"):
        assert phrase.lower() in upgrade.lower(), f"upgrade/recovery topic missing: {phrase}"
    for stale in ("responsive-layout work remains", "Bash integration currently provided"):
        assert stale not in readme, f"stale public claim remains: {stale}"

    gate = __import__("json").loads(text("release/v1.1.0.json"))
    beta = gate["external_beta"]
    assert gate["final_release_allowed"] is False, "final v1.1 gate opened prematurely"
    assert beta["required_reports"] >= 2
    assert beta["accepted_reports"] < beta["required_reports"]
    assert "original ThinkPad T480" in text("BETA_TESTING.md")
    assert "GitHub Actions Ubuntu runner" in text("BETA_TESTING.md")
    print("PASS  public documentation contract")


if __name__ == "__main__":
    main()
