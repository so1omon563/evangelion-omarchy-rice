#!/usr/bin/env python3
"""Shared-inheritance, contrast, compatibility, and preview transaction tests."""
import json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];CLI=ROOT/"bin/magi-theme-variant";REG=ROOT/"omarchy/theme-variants.json"
def luminance(value):
 channels=[]
 for offset in (0,2,4):
  channel=int(value[offset:offset+2],16)/255;channels.append(channel/12.92 if channel<=.04045 else ((channel+.055)/1.055)**2.4)
 return .2126*channels[0]+.7152*channels[1]+.0722*channels[2]
def contrast(a,b):
 high,low=sorted((luminance(a),luminance(b)),reverse=True);return (high+.05)/(low+.05)
def run(env,*args,ok=True):
 value=subprocess.run([str(CLI),*args],env=env,text=True,capture_output=True)
 if ok and value.returncode:raise AssertionError(value.stderr)
 return value
data=json.loads(REG.read_text());assert data["schema_version"]==1 and data["default"]=="standard"
assert set(data["variants"])=={"standard","oled","daylight","high-contrast"} and all(row["extends"]=="affinity" for row in data["variants"].values())
assert set(data["affinities"])=={"neutral","unit-00-prototype","unit-00-refit","unit-01","unit-02"}
wallpapers={item for rows in data["wallpaper_compatibility"].values() for item in rows}
assert wallpapers=={"1-nerv-command.png","2-eva-unit-01.png","3-magi-tokyo3.png","4-angel-alert.png","5-eva-unit-00-prototype.png","6-eva-unit-00-refit.png","7-eva-unit-02.png"}
with tempfile.TemporaryDirectory() as raw:
 base=Path(raw);state=base/"state";fake=base/"bin";fake.mkdir();log=base/"apply.log"
 helper=fake/"magi-affinity";helper.write_text("#!/bin/sh\nprintf '%s\\n' apply >> \"$EVA_VARIANT_TEST_LOG\"\n");helper.chmod(0o755)
 env={**os.environ,"PATH":str(fake)+os.pathsep+os.environ.get("PATH",""),"EVA_VARIANT_STATE":str(state),"EVA_VARIANT_REGISTRY":str(REG),"EVA_VARIANT_TEST_LOG":str(log)}
 for affinity in data["affinities"]:
  for variant in data["variants"]:
   row=json.loads(run(env,"resolve",affinity,variant).stdout);assert row["profile"]==affinity and row["variant"]==variant
   minimum=7 if variant=="high-contrast" else 4.5
   assert contrast(row["foreground"],row["background"])>=minimum,(affinity,variant,"foreground")
   assert contrast(row["foreground"],row["dark"])>=minimum,(affinity,variant,"panel")
   assert contrast(row["bar_icon"],row["dark"])>=4.5,(affinity,variant,"bar")
   assert contrast(row["accent"],row["background"])>=4.5,(affinity,variant,"accent")
 first=json.loads(run(env,"preview","oled").stdout);assert first["status"]=="previewed" and first["before"]=="standard"
 run(env,"preview","daylight");status=json.loads(run(env,"status").stdout);assert status["active"]=="daylight" and status["preview"]
 reverted=json.loads(run(env,"revert").stdout);assert reverted["active"]=="standard"
 run(env,"preview","oled");applied=json.loads(run(env,"apply","high-contrast").stdout);assert applied["status"]=="applied" and not applied["revert_available"]
 assert json.loads(run(env,"status").stdout)["active"]=="high-contrast" and not (state/"theme-variant-preview.json").exists()
 assert (state/"theme-variant").stat().st_mode & 0o777==0o600 and len(log.read_text().splitlines())==5
affinity=(ROOT/"bin/magi-affinity").read_text();terminal=(ROOT/"bin/eva-terminal-profile").read_text()
assert 'magi-theme-variant' in affinity and 'EVA_TERMINAL_BACKGROUND' in affinity and 'mode = "$color_mode"' in affinity
assert 'EVA_TERMINAL_SELECTION_TEXT' in terminal
print("PASS  inherited affinity treatment matrix contrast wallpaper compatibility terminal coordination and preview rollback")
