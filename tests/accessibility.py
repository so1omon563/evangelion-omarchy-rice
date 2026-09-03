#!/usr/bin/env python3
"""Automated contrast, geometry, keyboard, semantics, timeout, and motion audit."""
import json, re, sys, tomllib
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/"test-results/accessibility.json"

def luminance(value):
    rgb=[int(value[i:i+2],16)/255 for i in (1,3,5)]
    rgb=[x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4 for x in rgb]
    return .2126*rgb[0]+.7152*rgb[1]+.0722*rgb[2]

def contrast(a,b):
    x,y=luminance(a),luminance(b)
    return (max(x,y)+.05)/(min(x,y)+.05)

palette=tomllib.loads((ROOT/"theme/colors.toml").read_text())
background=palette["background"]
required=("foreground","dark_foreground","accent","yellow","cyan","bright_red")
ratios={name:round(contrast(palette[name],background),2) for name in required}
assert all(value>=4.5 for value in ratios.values()),ratios

plugins=ROOT/"omarchy/plugins"
popup=(plugins/"evangelion.motion/MotionPopupCard.qml").read_text()
assert all(x in popup for x in ('Accessible.role: Accessible.Dialog','Accessible.name: root.accessibleName','Shortcut { sequence: "Escape"','enabled: root.open'))

participants=("media","context","privacy","health","communications","mission","world-clock")
semantics={}
for name in participants:
    source=(plugins/f"evangelion.{name}/BarWidget.qml").read_text()
    semantics[name]=all(x in source for x in ("property string accessibleName","Accessible.role","Accessible.name","Accessible.description"))
assert all(semantics.values()),semantics

editors={
 "settings":plugins/"evangelion.settings/Service.qml",
 "scenes":plugins/"evangelion.scene-editor/Service.qml",
 "workspaces":plugins/"evangelion.workspace-names/Service.qml",
}
for name,path in editors.items():
    source=path.read_text()
    assert "WlrKeyboardFocus.Exclusive" in source and "Accessible.Dialog" in source and "Accessible.description" in source,name
    assert "Key_Escape" in source and "Key_Up" in source and "Key_Down" in source,name

lock=(plugins/"evangelion.lock/LockView.qml").read_text()
assert all(x in lock for x in ("Accessible.EditableText","Session password","echoMode: TextInput.Password","passwordMaskDelay: 0"))
assert "Accessible.name: passwordInput.text" not in lock
workspace=editors["workspaces"].read_text()
assert workspace.count("Accessible.EditableText")>=3 and all(x in workspace for x in ('workspaces.full_name','workspaces.short','workspaces.channel'))
assert 'Accessible.ignored: true' in (plugins/"evangelion.cava/BarWidget.qml").read_text()
assert 'Accessible.ignored: true' in (plugins/"evangelion.media/BarWidget.qml").read_text()

keyboard={
 "media":("Key_Space","Key_Left","Key_Right","Key_Plus","Key_Minus"),
 "context":("FocusScope","forceActiveFocus","Keys.onEscapePressed","Qt.Key_Return"),
 "clipboard":("forceActiveFocus","Keys.onPressed","Key_Escape"),
 "power":("focusTarget: keyCatcher","onCloseRequested: root.close()"),
}
paths={"media":plugins/"evangelion.media/BarWidget.qml","context":plugins/"evangelion.context/BarWidget.qml","clipboard":plugins/"evangelion.clipboard/Clipboard.qml","power":plugins/"evangelion.power/Panel.qml"}
assert all(all(token in paths[name].read_text() for token in tokens) for name,tokens in keyboard.items())

all_qml="\n".join(path.read_text() for path in plugins.rglob("*.qml"))
assert "#70667a" not in all_qml.lower() and "#82768d" not in all_qml.lower()
power=(plugins/"evangelion.power/Panel.qml").read_text()
assert "loops: Animation.Infinite" in power and "running: motion.full && root.charging" in power and "duration: 950" in power
for name in ("settings","scene-editor","workspace-names"):
    source=(plugins/f"evangelion.{name}/Service.qml").read_text()
    assert not re.search(r"Timer\s*\{[^}]*onTriggered:[^}]*opened\s*=\s*false",source,re.S),name

profiles=json.loads((ROOT/"tests/fixtures/responsive-layouts.json").read_text())["profiles"]
scales={row["monitor"]["scale"] for row in profiles}
assert {1.0,1.25,1.5,2.0}.issubset(scales)
geometry=[]
for row in profiles:
    m=row["monitor"];w=m["width"]/m["scale"];h=m["height"]/m["scale"]
    geometry.append({"name":row["name"],"logical_width":w,"logical_height":h,"usable":w>=640 and h>=480})
assert all(x["usable"] for x in geometry)

report={"schema_version":1,"status":"passed","contrast_ratios":ratios,"semantic_widgets":semantics,"display_profiles":geometry,
 "checks":{"normal_text_contrast":True,"keyboard_workflows":True,"screen_reader_labels":True,"password_private":True,"actionable_timeouts":False,"flashing_risk":"bounded","full_reduced_off":True}}
OUT.parent.mkdir(parents=True,exist_ok=True);OUT.write_text(json.dumps(report,indent=2)+"\n")
print("PASS  accessibility contrast geometry keyboard semantics timeout and motion matrix")
