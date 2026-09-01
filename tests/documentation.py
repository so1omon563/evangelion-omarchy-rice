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
                  "BETA_TESTING.md", "RELEASE_NOTES.md", "CONTEXT.md", "DEMO.md", "LOCALIZATION.md", "PERFORMANCE.md",
                  "RICE_HEALTH.md", "DISTRIBUTION_GUIDE.md", "MAINTAINING.md"):
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
                "operating-profiles.json", "motion.mode", "magi-motion", "magi-context", "context", "Cava", "Neon"):
        assert key.lower() in config.lower(), f"configuration topic missing: {key}"
    for topic in ("Shell", "plugins", "Services", "Wallpaper", "Weather", "Media",
                  "Cava", "temperature", "Hotkey"):
        assert topic.lower() in trouble.lower(), f"troubleshooting topic missing: {topic}"
    for phrase in ("so1omon.*", "evangelion.*", "rollback", "uninstall", "newest to oldest"):
        assert phrase.lower() in upgrade.lower(), f"upgrade/recovery topic missing: {phrase}"
    for stale in ("responsive-layout work remains", "Bash integration currently provided"):
        assert stale not in readme, f"stale public claim remains: {stale}"

    public_docs = "\n".join(text(name) for name in (
        "README.md", "BETA_TESTING.md", "RELEASE_ARTIFACTS.md", "ARCH_PACKAGING.md",
        "DISTRIBUTION.md", "MAINTAINING.md", "packaging/theme/README.md"))
    for stale in ("v1.4 candidate", "not required to install or release v1.1",
                  "Once the dedicated theme repository is published",
                  "packaging/arch/PKGBUILD` and"):
        assert stale not in public_docs, f"stale v1.4 publication claim remains: {stale}"
    assert "Upgrade from v1.3.1 to v1.4" in upgrade
    assert "releases/latest" in text("RELEASE_ARTIFACTS.md")
    assert "AUR publication is deferred" in text("ARCH_PACKAGING.md")

    distribution_guide = text("DISTRIBUTION_GUIDE.md")
    maintaining = text("MAINTAINING.md")
    release_notes = text("RELEASE_NOTES.md")
    for phrase in ("Just the look", "Complete MAGI desktop", "Managed Arch package",
                   "suite-internal", "not a published runtime", "Switching channels",
                   "prerequisites", "rollback", "removal", "Support covers"):
        assert phrase.lower() in distribution_guide.lower(), f"distribution guidance missing: {phrase}"
    for phrase in ("Synchronize a release candidate", "Theme gallery review",
                   "privacy-reviewed", "Final release checklist", "wait for the exact candidate CI",
                   "suite-internal", "no runtime artifact"):
        assert phrase.lower() in maintaining.lower(), f"maintainer guidance missing: {phrase}"
    for phrase in ("v1.4.0", "DISTRIBUTION_GUIDE.md", "MAINTAINING.md", "machine-readable"):
        assert phrase in release_notes, f"v1.4 release notes missing: {phrase}"

    gate = __import__("json").loads(text("release/v1.2.0.json"))
    community = gate["community_testing"]
    assert gate["final_release_allowed"] is True, "validated final v1.2 gate is closed"
    assert gate["candidate_commit"] == "9714cafea65e1886d4a5522bc44dfa83c7016513"
    assert gate["gates"]["candidate_ci"] == "passed-run-33423821933"
    assert community["required_reports"] == 0
    assert community["status"] == "optional-post-release"
    assert "reference ThinkPad T480" in text("BETA_TESTING.md")
    assert "GitHub Actions" in text("BETA_TESTING.md")
    v13 = __import__("json").loads(text("release/v1.3.0.json"))
    assert v13["final_release_allowed"] is True
    assert v13["candidate_commit"] == "d363835424b48989a0e16c8869672a9df56fe6fe"
    assert v13["gates"]["candidate_ci"] == "passed-run-33450358582"
    assert v13["community_testing"]["status"] == "optional-post-release"
    assert v13["community_testing"]["required_reports"] == 0
    v14 = __import__("json").loads(text("release/v1.4.0.json"))
    assert v14["final_release_allowed"] is True
    assert v14["candidate_commit"] == "2410a7643a48df5e663c61b2bad304028cad91bf"
    assert v14["gates"]["candidate_ci"] == "passed-run-33468175175"
    assert v14["distribution"]["plugins"] == "suite-internal-not-standalone"
    v141 = __import__("json").loads(text("release/v1.4.1.json"))
    assert v141["final_release_allowed"] is True
    assert v141["candidate_commit"] == "ef158578213ed80c88ae95678ec925b089ac593d"
    assert v141["gates"]["candidate_ci"] == "passed-run-33470493258"
    print("PASS  public documentation contract")


if __name__ == "__main__":
    main()
