#!/usr/bin/env python3
"""Arch package ownership and explicit per-user lifecycle contracts."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args, cwd=None, env=None):
    result = subprocess.run(args, cwd=cwd, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode:
        raise AssertionError(f"command failed ({result.returncode}): {' '.join(map(str,args))}\n{result.stdout}")
    return result


with tempfile.TemporaryDirectory(prefix="evangelion-arch-test-") as raw:
    tmp = Path(raw); source = tmp / "source"
    shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns(".git", "build", "test-results", "__pycache__", "*.pyc"))
    run("git", "init", "--quiet", cwd=source)
    run("git", "add", ".", cwd=source)
    run("git", "-c", "user.name=Package Test", "-c", "user.email=test@example.invalid",
        "commit", "--quiet", "-m", "package fixture", cwd=source)
    run("git", "tag", "v0.0.0-ci.2", cwd=source)
    release = tmp / "release"
    run(source / "scripts/build-release", "build", "--tag", "v0.0.0-ci.2", "--output", release, cwd=source)
    archive = release / "evangelion-omarchy-rice-0.0.0-ci.2.tar.gz"
    arch = tmp / "arch"
    run(source / "scripts/build-arch-package", archive, "--output", arch, cwd=source)
    pkgbuild = (arch / "PKGBUILD").read_text()
    assert "@VERSION@" not in pkgbuild and "@PKGVER@" not in pkgbuild and "@SHA256@" not in pkgbuild
    assert "pkgver=0.0.0_ci.2" in pkgbuild and "sha256sums=('SKIP')" not in pkgbuild
    assert "install=" not in pkgbuild and ".install" not in pkgbuild
    run("makepkg", "--printsrcinfo", cwd=arch)
    vcs_dir = tmp / "vcs"
    vcs_dir.mkdir()
    shutil.copy2(source / "packaging/arch/PKGBUILD-git", vcs_dir / "PKGBUILD")
    vcs_info = run("makepkg", "--printsrcinfo", cwd=vcs_dir).stdout
    assert "provides = evangelion-omarchy-rice" in vcs_info
    assert "conflicts = evangelion-omarchy-rice" in vcs_info
    assert "packaging/release/allowlist.txt" in (vcs_dir / "PKGBUILD").read_text()

    srcdir, pkgdir = tmp / "src", tmp / "pkg"
    srcdir.mkdir(); pkgdir.mkdir()
    with tarfile.open(archive, "r:gz") as tar:
        tar.extractall(srcdir, filter="data")
    package_cmd = f'source "{arch}/PKGBUILD"; srcdir="{srcdir}"; pkgdir="{pkgdir}"; package'
    run("bash", "-c", package_cmd, cwd=arch)
    share = pkgdir / "usr/share/evangelion-rice"
    launcher = pkgdir / "usr/bin/evangelion-rice"
    assert share.is_dir() and os.access(launcher, os.X_OK)
    assert set(path.name for path in pkgdir.iterdir()) == {"usr"}
    assert not any("home" in path.parts for path in pkgdir.rglob("*"))

    if shutil.which("namcap"):
        run("namcap", str(arch / "PKGBUILD"), cwd=arch)

    home, state = tmp / "home", tmp / "state"
    home.mkdir(); state.mkdir()
    env = os.environ | {"HOME": str(home), "XDG_STATE_HOME": str(state),
                        "EVANGELION_RICE_ROOT": str(share), "EVANGELION_SKIP_ACTIVATE": "1",
                        "EVANGELION_SOURCE_ONLY": "1", "EVANGELION_RELEASE_ARTIFACT_NESTED": "1",
                        "EVANGELION_RELEASE_131_NESTED": "1"}
    before = sorted(str(path.relative_to(home)) for path in home.rglob("*"))
    status = json.loads(run(launcher, "status", "--json", env=env).stdout)
    assert status["package_version"] == "0.0.0-ci.2" and status["activated"] is False
    assert sorted(str(path.relative_to(home)) for path in home.rglob("*")) == before
    run(launcher, "plan", "--preset", "minimal", env=env)
    assert sorted(str(path.relative_to(home)) for path in home.rglob("*")) == before
    run(launcher, "setup", "--yes", "--preset", "minimal", env=env)
    assert json.loads(run(launcher, "status", "--json", env=env).stdout)["activated"] is True
    run(launcher, "upgrade", "--yes", "--preset", "minimal", env=env)
    run(launcher, "deactivate", env=env)
    assert json.loads(run(launcher, "status", "--json", env=env).stdout)["activated"] is False

    report = {"schema_version": 1, "status": "passed", "package_version": "0.0.0-ci.2",
              "checks": ["release-pkgbuild", "vcs-pkgbuild", "srcinfo", "package-root-only",
                         "no-home-mutation", "dependency-contract", "plan", "setup", "upgrade",
                         "status", "rollback", "deactivate", "no-install-hook", "aur-not-published"]}
    output = Path(os.environ.get("EVANGELION_ARCH_PACKAGE_REPORT", ROOT / "test-results/arch-package.json"))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n")

print("PASS  Arch package ownership and explicit per-user lifecycle")
