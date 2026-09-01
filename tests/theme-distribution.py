#!/usr/bin/env python3
"""Standalone Omarchy theme export and clean-user lifecycle."""
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "scripts/export-theme"
DENIED = {"alacritty.toml", "foot.ini", "ghostty.conf", "kitty.conf", "vscode.json"}


def digest(tree: Path) -> str:
    result = hashlib.sha256()
    for path in sorted(p for p in tree.rglob("*") if p.is_file()):
        result.update(str(path.relative_to(tree)).encode() + b"\0")
        result.update(path.read_bytes())
    return result.hexdigest()


with tempfile.TemporaryDirectory() as directory:
    temp = Path(directory)
    exported = temp / "exported"
    subprocess.run([EXPORT, exported], check=True, stdout=subprocess.DEVNULL)

    required = {"colors.toml", "README.md", "LICENSE", "ASSETS_LICENSE.md", "ARTWORK.md",
                "preview.png", "backgrounds.sha256", ".distribution.json"}
    assert required <= {p.name for p in exported.iterdir()}
    assert len(list((exported / "backgrounds").glob("*.png"))) == 7
    subprocess.run(["sha256sum", "--check", "--status", "backgrounds.sha256"],
                   cwd=exported, check=True)
    for path in exported.rglob("*"):
        assert not path.is_symlink()
        if path.is_file():
            assert path.name not in DENIED and path.suffix != ".lua"
            assert not path.stat().st_mode & 0o111

    first = digest(exported)
    (exported / "stale-file").write_text("must disappear on synchronization")
    subprocess.run([EXPORT, exported], check=True, stdout=subprocess.DEVNULL)
    assert not (exported / "stale-file").exists()
    assert digest(exported) == first

    # Mimic `omarchy theme install`: clone a repository whose name resolves to
    # `evangelion`, then stage its declarative contents without suite files.
    subprocess.run(["git", "init", "--quiet", "--initial-branch=main"], cwd=exported, check=True)
    subprocess.run(["git", "add", "."], cwd=exported, check=True)
    subprocess.run(["git", "-c", "user.name=Theme Test", "-c", "user.email=theme@example.invalid",
                    "commit", "--quiet", "-m", "theme"], cwd=exported, check=True)
    home = temp / "home"
    installed = home / ".config/omarchy/themes/evangelion"
    installed.parent.mkdir(parents=True)
    subprocess.run(["git", "clone", "--quiet", exported, installed], check=True)
    assert (installed / "colors.toml").is_file()

    current = home / ".local/state/omarchy/current"
    staged = current / "theme"
    staged.mkdir(parents=True)
    for path in installed.iterdir():
        if path.name == ".git" or path.name in DENIED or path.suffix == ".lua":
            continue
        target = staged / path.name
        shutil.copytree(path, target) if path.is_dir() else shutil.copy2(path, target)
    backgrounds = sorted((staged / "backgrounds").glob("*.png"))
    assert len(backgrounds) == 7
    background_link = current / "background"
    seen = []
    for path in backgrounds:
        background_link.unlink(missing_ok=True)
        background_link.symlink_to(path)
        seen.append(background_link.resolve().name)
    assert seen == [p.name for p in backgrounds]

    # Updating the clone changes only the named theme. Removal after switching
    # away leaves unrelated user configuration untouched.
    unrelated = home / ".config/omarchy/themes/personal/colors.toml"
    unrelated.parent.mkdir(parents=True)
    unrelated.write_text("accent = '#ffffff'\n")
    subprocess.run(["git", "pull", "--ff-only", "--quiet"], cwd=installed, check=True)
    shutil.rmtree(installed)
    assert unrelated.read_text() == "accent = '#ffffff'\n"

    metadata = json.loads((exported / ".distribution.json").read_text())
    assert metadata["name"] == "evangelion" and metadata["derived_from_suite"] == "v1.3.1"
    suite_url = "https://github.com/so1omon563/evangelion-omarchy-rice"
    assert metadata["suite_homepage"] == suite_url
    readme = (exported / "README.md").read_text()
    assert "Want the complete MAGI desktop?" in readme and suite_url in readme
    assert "does not silently install or enable any suite component" in " ".join(readme.split())

print("PASS  standalone theme export install apply cycle update and removal")
