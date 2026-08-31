import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion
Item{id:root;property var shell:null;property bool opened:false;property string status:"idle";property string phase:"none";property string recovery:"";property int exitCode:0
Motion.MotionState{id:motion}
readonly property var targetScreen:{var focused=Hyprland.focusedMonitor;var screens=Quickshell.screens||[];if(focused)for(var i=0;i<screens.length;i++)if(screens[i].name===focused.name)return screens[i];return screens.length?screens[0]:null}
function loadState(raw){try{var s=JSON.parse(String(raw));root.status=s.status;root.phase=s.phase;root.recovery=s.recovery||"";root.exitCode=s.exit_code||0;root.opened=root.status!=="idle";if(root.status!=="active")retire.restart()}catch(e){root.status="idle";root.phase="none";root.opened=false}}
FileView{id:stateView;path:Quickshell.env("HOME")+"/.local/state/evangelion-rice/update-operation/state.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:root.loadState(text());onLoadFailed:root.loadState("{}")}
Timer{id:retire;interval:5000;onTriggered:root.opened=false}
IpcHandler{target:"update-operation";function reload():string{stateView.reload();motion.refresh();return"reloading"}function state():string{return JSON.stringify({visible:root.opened,status:root.status,phase:root.phase,recovery:root.recovery,exitCode:root.exitCode,motionMode:motion.mode})}}
PanelWindow{visible:root.opened;screen:root.targetScreen;anchors{top:true;right:true;bottom:true;left:true}color:"transparent";exclusionMode:ExclusionMode.Ignore;mask:Region{}
WlrLayershell.namespace:"magi-update-operation";WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
Rectangle{width:Math.min(430,parent.width-24);height:Math.min(root.status==="failed"?146:120,parent.height-24);anchors.right:parent.right;anchors.rightMargin:12;anchors.top:parent.top;anchors.topMargin:Math.min(58,Math.max(12,parent.height*0.06));radius:3;color:"#ed080710";border.width:2;border.color:root.status==="failed"?"#ff4055":root.status==="complete"?"#9cf23a":"#62d8ff";opacity:root.opened?1:0
Behavior on opacity{enabled:root.status!=="failed"&&!motion.off;NumberAnimation{duration:motion.standardMs;easing.type:Easing.OutCubic}}
Column{anchors{fill:parent;leftMargin:24;rightMargin:20;topMargin:18;bottomMargin:16}spacing:8
Text{text:root.status==="active"?"MAGI MAINTENANCE // ACTIVE":root.status==="complete"?"SYSTEM UPDATE // COMPLETE":"SYSTEM UPDATE // FAILED";color:parent.parent.border.color;font.family:"JetBrainsMono Nerd Font";font.pixelSize:17;font.bold:true}Rectangle{width:parent.width;height:1;color:"#7450a6"}Text{text:"PHASE  ·  "+root.phase.toUpperCase();color:"#eee8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;font.bold:true}Text{visible:root.status==="failed";text:"RECOVERY  ·  "+root.recovery;color:"#f6a52f";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}}}}}
