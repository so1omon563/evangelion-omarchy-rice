import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id: root
  property var shell: null
  property bool initialized: false
  property bool opened: false
  Motion.MotionState { id: motion }
  readonly property bool reducedMotion: !motion.full
  property int lastScreenCount: 0
  property int screenCount: Quickshell.screens.length
  property int eventCount: 0
  property string heading: "EXTERNAL DEVICE // CONNECTED"
  property string detail: "USB STORAGE"
  property string actionHint: ""
  property color accent: "#62d8ff"
  property var recent: ({})
  readonly property int cooldownMs: 5000
  readonly property var targetScreen: {
    var focused = Hyprland.focusedMonitor
    var screens = Quickshell.screens || []
    if (focused) for (var i = 0; i < screens.length; i++) if (screens[i].name === focused.name) return screens[i]
    return screens.length ? screens[0] : null
  }

  function copy(kind) {
    var values={storage:["EXTERNAL STORAGE","󰋊"],dock:["UMBILICAL DOCK","󰚥"],display:["DISPLAY LINK","󰍹"],keyboard:["CONTROL INTERFACE","󰌌"],pointer:["POINTING DEVICE","󰍽"],audio:["AUDIO INTERFACE","󰕾"]}
    return values[kind] || ["EXTERNAL DEVICE","󰋐"]
  }
  function show(kind, action, label, genuine) {
    var key=kind+":"+action+":"+label, now=Date.now()
    if (genuine && recent[key] && now-recent[key] < cooldownMs) return
    if (genuine) { recent[key]=now; eventCount++ }
    var words=copy(kind), connected=action!=="disconnected"
    heading=words[0]+" // "+(connected?"CONNECTED":"DISCONNECTED")
    detail=String(label||words[0]).toUpperCase().slice(0,52)
    actionHint=kind==="storage" && connected ? "SAFE ACTION  ›  magi-device-osd open" : ""
    accent=connected ? "#62d8ff" : "#f6a52f"
    opened=true; retire.restart()
  }
  onScreenCountChanged: {
    if (!initialized) { lastScreenCount=screenCount; initialized=true; return }
    displaySettle.restart()
  }
  Component.onCompleted: { lastScreenCount=screenCount; initialized=true }

  Timer { id: displaySettle; interval: 1400; onTriggered: { var action=root.screenCount>root.lastScreenCount?"connected":"disconnected"; if(root.screenCount!==root.lastScreenCount) root.show("display",action,root.screenCount+" ACTIVE OUTPUT"+(root.screenCount===1?"":"S"),true); root.lastScreenCount=root.screenCount } }
  Timer { id: retire; interval: motion.full ? 2600 : 2800; onTriggered: root.opened=false }

  Process {
    id: monitor
    running: true
    command: ["magi-device-monitor"]
    stdout: SplitParser { onRead: function(line) { try { var e=JSON.parse(String(line)); root.show(e.kind,e.action,e.label,true) } catch(err) {} } }
  }

  IpcHandler {
    target: "device-osd"
    function preview(kind:string, action:string):string { root.show(kind,action,kind.replace("-"," "),false); return root.heading }
    function hide():string { root.opened=false; retire.stop(); return "hidden" }
    function state():string { return JSON.stringify({initialized:root.initialized,visible:root.opened,screens:root.screenCount,eventCount:root.eventCount,cooldownMs:root.cooldownMs,motionMode:motion.mode,heading:root.heading}) }
  }

  PanelWindow {
    screen: root.targetScreen
    visible: root.opened
    anchors { top:true; right:true; bottom:true; left:true }
    color:"transparent"; exclusionMode:ExclusionMode.Ignore; mask:Region {}
    WlrLayershell.namespace:"magi-device-osd"; WlrLayershell.layer:WlrLayer.Overlay; WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
    Rectangle {
      width:Math.min(520,parent.width-32,Math.max(280,parent.width*0.45)); height:root.actionHint===""?132:154
      anchors.left:parent.left; anchors.leftMargin:Math.min(Math.max(16,parent.width*0.055),(parent.width-width)/2); anchors.verticalCenter:parent.verticalCenter
      radius:3; color:"#ed080710"; border.width:2; border.color:root.accent
      opacity:root.opened?1:0
      Behavior on opacity { enabled:!motion.off; NumberAnimation{duration:motion.standardMs} }
      Rectangle {
        width: 8
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: root.accent
      }
      Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 32; rightMargin: 24 }
        spacing: 9
        Text {width:parent.width;text:root.heading;color:root.accent;elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font";font.pixelSize:20;font.bold:true;font.letterSpacing:1.0}
        Rectangle {width:parent.width;height:1;color:"#7450a6"}
        Text {width:parent.width;text:root.detail;color:"#eee8ff";elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;font.bold:true;font.letterSpacing:0.7}
        Text {visible:root.actionHint!=="";text:root.actionHint;color:"#9cf23a";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}
      }
    }
  }
}
