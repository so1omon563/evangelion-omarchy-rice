#!/usr/bin/env python3
"""Multi-source media, artwork privacy, keyboard, and Cava coordination contract."""
import json, os, subprocess, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MEDIA=ROOT/"omarchy/plugins/evangelion.media/BarWidget.qml"
CAVA=ROOT/"omarchy/plugins/evangelion.cava/BarWidget.qml"

config=json.loads((ROOT/"omarchy/media.json").read_text())
assert config["schema_version"]==1
assert config["artwork"]=={"allow_remote":False,"cache":"none"}
assert config["cava"]["mode"]=="playing" and config["cava"]["paused_behavior"]=="standby"
assert 1 <= config["volume_step_percent"] <= 20

media=MEDIA.read_text();cava=CAVA.read_text()
for phrase in ('sourcePlayers','selectPlayer','trackAlbum','trackArtUrl','allowRemoteArtwork','file:','https://','player.position','player.length','player.volume','Key_Up','Key_Down','Key_Space','Key_Left','Key_Right','Key_Plus','Key_Minus','Style.space(compactBar ? 116 : 190)'):
    assert phrase in media,phrase
for phrase in ('firstPartyServiceFor("omarchy.media")','activePlayer','root.shouldRun','cavaMode === "always" || playing','pausedBehavior === "standby"','running: root.shouldRun'):
    assert phrase in cava,phrase
assert 'visible: cavaAvailable && cavaMode !== "off" && hasMedia' in cava
assert 'source: root.artworkSource' in media and 'cache": "none"' in (ROOT/"omarchy/media.json").read_text()

with tempfile.TemporaryDirectory() as raw:
    base=Path(raw);bindir=base/"bin";bindir.mkdir();log=base/"log"
    playerctl=bindir/"playerctl";playerctl.write_text('''#!/bin/sh
printf 'playerctl %s\n' "$*" >> "$MEDIA_LOG"
case "$1" in
 -l) printf 'playerctld\nfirefox\nchromium\n';;
 --player=firefox) [ "$2" = status ] && printf 'Playing\n';;
 --player=chromium) [ "$2" = status ] && printf 'Paused\n';;
 --player=playerctld) [ "$2" = status ] && printf 'Paused\n';;
esac
''');playerctl.chmod(0o755)
    shell=bindir/"omarchy-shell";shell.write_text('''#!/bin/sh
printf 'shell %s\n' "$*" >> "$MEDIA_LOG"
[ "$3" = status ] && printf '{"hasPlayer":true,"playing":true,"title":"Test Track","artist":"Test Artist"}\n'
''');shell.chmod(0o755)
    env={**os.environ,"PATH":str(bindir)+":"+os.environ["PATH"],"MEDIA_LOG":str(log)}
    def run(*args): return subprocess.run([str(ROOT/"bin/magi-media"),*args],env=env,text=True,capture_output=True,check=True)
    assert "Test Track" in run("status").stdout
    assert json.loads(run("status","--json").stdout)["title"]=="Test Track"
    run("play-pause");run("source-next");run("volume-down")
    output=log.read_text()
    assert "shell -q media playPause" in output and "shell -q media sourceNext" in output
    assert "playerctl --player=firefox volume 0.05-" in output

snapshot=json.loads((ROOT/"omarchy/snapshot-manifest.json").read_text())
assert any(x["path"]=="omarchy/media.json" for x in snapshot["components"]["settings"])
print("PASS  coordinated media Playerctl Cava artwork privacy keyboard and geometry")
