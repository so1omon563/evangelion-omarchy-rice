#!/usr/bin/env python3
"""v1.3.1 mixed-bundle and exact v1.3.0 upgrade regressions."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def git_show(path):
    return subprocess.run(["git", "show", f"v1.3.0:{path}"], cwd=ROOT, check=True,
                          text=True, capture_output=True).stdout


def run_paint(function_source, data, include_badge):
    nodes = ["rail-affinity", "rail-workspace", "rail-profile", "rail-uptime", "rail-network"]
    if include_badge:
        nodes.append("rail-affinity-state")
    script = f"""
const nodes = Object.fromEntries({json.dumps(nodes)}.map(id => [id, {{textContent:'',style:{{}}}}]));
const document = {{body:{{dataset:{{}}}}}};
const $ = id => nodes[id] || null;
function formatUptime() {{ return '00H 00M'; }}
{function_source}
paintRail({json.dumps(data)});
console.log(JSON.stringify(nodes));
"""
    return subprocess.run(["node", "-e", script], text=True, capture_output=True)


def function(source, name):
    start = source.index(f"function {name}(")
    next_function = source.find("\nfunction ", start + 1)
    return source[start: next_function if next_function >= 0 else len(source)]


current_app = (ROOT / "start-page/app.js").read_text()
current_html = (ROOT / "start-page/index.html").read_text()
old_app = git_show("start-page/app.js")
old_html = git_show("start-page/index.html")
data = {"affinity":{"mode":"auto","active":"unit-00-prototype","label":"UNIT-00 PROTOTYPE","state":"current"},
        "workspace":{"available":True,"id":1,"label":"MAGI-01 · MELCHIOR"},
        "profile":"mobile","uptime":60,"network":{"online":True}}

# Old HTML with current JS must no longer fail merely because the badge is absent.
mixed_old_html = run_paint(function(current_app, "paintRail"), data, False)
assert mixed_old_html.returncode == 0, mixed_old_html.stderr
painted = json.loads(mixed_old_html.stdout)
assert "MELCHIOR" in painted["rail-workspace"]["textContent"]
assert painted["rail-profile"]["textContent"] == "MOBILE"

# The reverse mix reproduced the user-visible failure, so versioned URLs must
# ensure the old renderer can never be selected by the current HTML.
mixed_old_js = run_paint(function(old_app, "paintRail"), data, True)
assert mixed_old_js.returncode != 0 and "toUpperCase" in mixed_old_js.stderr
assert 'app.js?v=' in current_html and 'style.css?v=' in current_html
assert 'app.js?v=' not in old_html
server = (ROOT / "start-page/server.py").read_text()
assert '"Cache-Control", "no-store, max-age=0"' in server

# Exercise an exact v1.3.0 install, current upgrade, upgrade rollback, repeat
# upgrade, and uninstall-equivalent rollback in an isolated home.
with tempfile.TemporaryDirectory() as directory:
    temp = Path(directory)
    archive = temp / "v1.3.0.tar"
    old = temp / "old"
    home = temp / "home"
    state = temp / "state"
    old.mkdir(); home.mkdir()
    subprocess.run(["git", "archive", "--format=tar", f"--output={archive}", "v1.3.0"], cwd=ROOT, check=True)
    subprocess.run(["tar", "-xf", archive, "-C", old], check=True)
    env = os.environ | {"HOME": str(home), "XDG_STATE_HOME": str(state), "EVANGELION_SKIP_ACTIVATE": "1",
                        "EVANGELION_RELEASE_131_NESTED": "1"}
    def install(source):
        subprocess.run([str(source / "install.sh"), "--apply", "--preset", "default", "--yes"], env=env,
                       check=True, stdout=subprocess.DEVNULL)
        return Path((state / "evangelion-rice/last-install-backup").read_text().strip())
    initial = install(old)
    assert 'app.js?v=' not in (home / ".local/share/evangelion-rice/start-page/index.html").read_text()
    upgrade = install(ROOT)
    assert 'app.js?v=' in (home / ".local/share/evangelion-rice/start-page/index.html").read_text()
    subprocess.run([str(ROOT / "rollback.sh"), str(upgrade)], env=env, check=True, stdout=subprocess.DEVNULL)
    assert 'app.js?v=' not in (home / ".local/share/evangelion-rice/start-page/index.html").read_text()
    repeat_upgrade = install(ROOT)
    subprocess.run([str(ROOT / "rollback.sh"), str(repeat_upgrade)], env=env, check=True, stdout=subprocess.DEVNULL)
    subprocess.run([str(ROOT / "rollback.sh"), str(initial)], env=env, check=True, stdout=subprocess.DEVNULL)
    assert not (home / ".config/omarchy/themes/evangelion/colors.toml").exists()
    assert not (home / ".local/share/evangelion-rice/start-page/index.html").exists()

print("PASS  v1.3.1 mixed browser bundles and exact v1.3.0 upgrade lifecycle")
