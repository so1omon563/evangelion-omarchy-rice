#!/usr/bin/env python3
import json, os, subprocess, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def write(path,value): path.parent.mkdir(parents=True,exist_ok=True); path.write_text(str(value))
def probe(sysroot, command_path):
    env=os.environ|{"EVA_SYS_ROOT":str(sysroot),"EVA_COMMAND_PATH":str(command_path)}
    return json.loads(subprocess.run([str(ROOT/"bin/eva-capabilities")],env=env,text=True,capture_output=True,check=True).stdout)
def thermal_status(sysroot, state):
    env=os.environ|{"EVA_SYS_ROOT":str(sysroot),"XDG_STATE_HOME":str(state)}
    return json.loads(subprocess.run([str(ROOT/"bin/magi-thermal-alert"),"status"],env=env,text=True,capture_output=True,check=True).stdout)
with tempfile.TemporaryDirectory() as temporary:
    base=Path(temporary); empty=base/"empty"; empty.mkdir(); commands=base/"commands"; commands.mkdir()
    unavailable=probe(empty,commands)
    assert unavailable["battery"]["available"] is False and unavailable["thermal"]["available"] is False
    assert unavailable["network_manager"] is False and unavailable["brightness"] is False

    intel=base/"intel"; write(intel/"class/hwmon/hwmon0/name","coretemp\n"); write(intel/"class/hwmon/hwmon0/temp1_input","55000\n")
    assert probe(intel,commands)["thermal"]["families"]==["intel"]
    assert thermal_status(intel,base/"state-intel")["sensor"]=="intel:coretemp"

    amd=base/"amd"; write(amd/"class/hwmon/hwmon0/name","k10temp\n"); write(amd/"class/hwmon/hwmon0/temp1_input","61000\n")
    assert probe(amd,commands)["thermal"]["families"]==["amd"]
    assert thermal_status(amd,base/"state-amd")["sensor"]=="amd:k10temp"
    assert thermal_status(empty,base/"state-empty")["available"] is False

    multi=base/"multi"
    for name,capacity in (("BAT0",80),("BAT1",45)):
        write(multi/f"class/power_supply/{name}/capacity",f"{capacity}\n"); write(multi/f"class/power_supply/{name}/status","Discharging\n")
    assert len(probe(multi,commands)["battery"]["devices"])==2

    for name in ("nmcli","busctl","tailscale","brightnessctl","powerprofilesctl","wpctl","cava"):
        path=commands/name; path.write_text("#!/bin/sh\nexit 0\n"); path.chmod(0o755)
    available=probe(empty,commands)
    assert available["network_manager"] and available["bluetooth_tools"] and available["tailscale"]
    assert available["brightness"] and available["power_profiles"] and available["audio"]=="pipewire" and available["cava"]
print("PASS  mocked capability matrix")
