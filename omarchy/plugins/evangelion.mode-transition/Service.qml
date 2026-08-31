import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id: root
  property var shell: null
  property bool opened: false
  property string modeName: "MAGI"
  property string phase: "ACTIVE"
  property string detail: "OPERATING PARAMETERS SYNCHRONIZED"
  property color accent: "#9cf23a"
  property int eventCount: 0
  Motion.MotionState { id: motion }
  readonly property var targetScreen: {
    var focused=Hyprland.focusedMonitor, screens=Quickshell.screens||[]
    if(focused) for(var i=0;i<screens.length;i++) if(screens[i].name===focused.name) return screens[i]
    return screens.length?screens[0]:null
  }

  function copy(name) {
    var values={"presentation":["MAGI PRESENTATION","VISUAL TELEMETRY CHANNEL","#62d8ff"],"deployment":["EVA DEPLOYMENT","MISSION WORKSPACE","#f6a52f"],"at-field":["A.T. FIELD","COMMUNICATION BARRIER","#ffd166"],"angel":["ANGEL INTRUSION","CONDITION ONE SIMULATION","#ff4055"],"docked":["UMBILICAL DOCK","EXTERNAL OPERATIONS PROFILE","#62d8ff"],"mobile":["MOBILE OPERATIONS","INTERNAL SYSTEM PROFILE","#9cf23a"],"terminal-context":["TERMINAL CONTEXT","ISOLATED PROFILE","#b76cff"]}
    return values[name]||[String(name||"MAGI").toUpperCase(),"OPERATING MODE","#9cf23a"]
  }
  function show(name,nextPhase,nextDetail) {
    var words=copy(name)
    modeName=words[0]; phase=String(nextPhase||"active").toUpperCase()
    detail=String(nextDetail||words[1]).toUpperCase().slice(0,64); accent=words[2]
    opened=true; eventCount++; retire.restart()
  }
  function hide() { opened=false; retire.stop() }
  Timer { id: retire; interval: motion.full?1800:(motion.reduced?1400:1100); onTriggered:root.opened=false }
  IpcHandler {
    target:"mode-transition"
    function show(name:string,phase:string,detail:string):string { root.show(name,phase,detail); return root.modeName+" // "+root.phase }
    function hide():string { root.hide(); return "hidden" }
    function state():string { return JSON.stringify({visible:root.opened,mode:root.modeName,phase:root.phase,detail:root.detail,motionMode:motion.mode,eventCount:root.eventCount}) }
  }
  PanelWindow {
    visible:root.opened; screen:root.targetScreen
    anchors{top:true;right:true;bottom:true;left:true}
    color:"transparent"; exclusionMode:ExclusionMode.Ignore; mask:Region{}
    WlrLayershell.namespace:"magi-mode-transition"; WlrLayershell.layer:WlrLayer.Overlay; WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
    Rectangle {
      id:card; width:Math.min(440,parent.width-32); height:104
      anchors.left:parent.left; anchors.leftMargin:Math.min(Math.max(16,parent.width*0.045),(parent.width-width)/2)
      anchors.bottom:parent.bottom; anchors.bottomMargin:Math.max(20,parent.height*0.07)
      color:"#ed080710"; radius:3; border.width:2; border.color:root.accent
      opacity:root.opened?1:0
      transform:Translate{x:root.opened||!motion.full?0:-10}
      Behavior on opacity{enabled:!motion.off;NumberAnimation{duration:motion.standardMs}}
      Rectangle {
        width: 8
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: root.accent
      }
      Column {
        anchors {
          left: parent.left
          right: parent.right
          verticalCenter: parent.verticalCenter
          leftMargin: 30
          rightMargin: 20
        }
        spacing: 7
        Text{width:parent.width;text:root.modeName+" // "+root.phase;color:root.accent;elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font";font.pixelSize:18;font.bold:true;font.letterSpacing:1}
        Rectangle{width:parent.width;height:1;color:"#7450a6"}
        Text{width:parent.width;text:root.detail;color:"#eee8ff";elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true;font.letterSpacing:.6}
      }
    }
  }
}
