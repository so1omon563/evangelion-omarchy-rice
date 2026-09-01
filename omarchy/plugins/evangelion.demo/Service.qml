import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id:root
  property var model:({active:false,scenario:"neutral-nominal",accent:"#f6d447",status:"nominal",media:({}),privacy:({})})
  readonly property bool active:model.active===true
  readonly property var targetScreen:(Quickshell.screens||[]).length?Quickshell.screens[0]:null
  Motion.MotionState { id:motion }
  function refresh(){ if(!probe.running) probe.running=true }
  function accept(value){ try { model=JSON.parse(String(value)) } catch(error){} }
  function command(action){ runner.command=["magi-demo",action]; runner.running=true }
  FileView { path:Quickshell.env("HOME")+"/.local/state/evangelion-rice/demo/state.json"; watchChanges:true; printErrors:false; onFileChanged:root.refresh() }
  Process { id:probe; running:true; command:["magi-demo","status","--json"]; stdout:StdioCollector { onStreamFinished:root.accept(text) } }
  Process { id:runner; onExited:root.refresh() }
  IpcHandler { target:"magi-demo"
    function open():string { root.command("enter"); return "queued" }
    function next():string { root.command("next"); return "queued" }
    function previous():string { root.command("previous"); return "queued" }
    function close():string { root.command("exit"); return "queued" }
    function refresh():string { root.refresh(); return "ok" }
  }
  PanelWindow {
    screen:root.targetScreen; visible:root.active; color:"transparent"
    anchors { top:true; left:true; right:true; bottom:true }
    WlrLayershell.namespace:"magi-demo"; WlrLayershell.layer:WlrLayer.Overlay; WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
    Rectangle {
      anchors.fill:parent; anchors.margins:42; color:"#f0080710"; border.width:2; border.color:root.model.accent; radius:4
      opacity:root.active?1:0
      Behavior on opacity { enabled:!motion.off; NumberAnimation { duration:motion.full?180:80 } }
      Rectangle {
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
        height: 54
        color: root.model.accent
        Text { anchors.centerIn:parent; text:"DEMONSTRATION MODE  //  FICTIONAL DATA  //  LIVE PROVIDERS DISCONNECTED"; color:"#09070d"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:16; font.bold:true; font.letterSpacing:1 }
      }
      Column {
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          bottom: parent.bottom
          margins: 28
          topMargin: 82
        }
        spacing: 18
        Row { width:parent.width
          Column { width:parent.width*.67; spacing:5
            Text { text:"MAGI // FULL INTERFACE DEMONSTRATOR"; color:root.model.accent; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:22; font.bold:true }
            Text { text:String(root.model.scenario).toUpperCase()+"  ·  "+String(root.model.affinity).toUpperCase(); color:"#eee8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:13; font.bold:true }
          }
          Text { width:parent.width*.33; horizontalAlignment:Text.AlignRight; text:String(root.model.status).toUpperCase(); color:root.model.accent; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:24; font.bold:true }
        }
        Grid { width:parent.width; columns:3; spacing:12
          Repeater { model:[
            ["WORKSPACE",String(root.model.workspace_id).padStart(2,"0")+" // "+root.model.workspace],
            ["OPERATING PROFILE",String(root.model.profile).toUpperCase()],
            ["SYSTEM CONTEXT",String(root.model.summary).toUpperCase()],
            ["INTERNAL POWER",String(root.model.battery_percent)+"%"],
            ["THERMAL BUS",String(root.model.temperature_c)+"°C"],
            ["UPLINK",root.model.online?"TOKYO-3 RELAY ONLINE":"LINK ISOLATED"]
          ]; delegate:Rectangle { required property var modelData; width:(parent.width-24)/3; height:94; color:"#b30d0b12"; border.width:1; border.color:root.model.accent
            Column { anchors.fill:parent; anchors.margins:14; spacing:9
              Text { text:modelData[0]; color:root.model.accent; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10; font.bold:true; font.letterSpacing:1 }
              Text { width:parent.width; text:modelData[1]; elide:Text.ElideRight; color:"#eee8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:14; font.bold:true }
            }
          } }
        }
        Rectangle { width:parent.width; height:112; color:"#b30d0b12"; border.width:1; border.color:"#7450a6"
          Row { anchors.fill:parent; anchors.margins:16; spacing:20
            Column { width:parent.width*.58; spacing:8
              Text { text:"AUDIO CHANNEL // "+String(root.model.media?.state||"standby").toUpperCase(); color:root.model.accent; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; font.bold:true }
              Text { text:String(root.model.media?.title||""); color:"#eee8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:18; font.bold:true }
              Text { text:String(root.model.media?.artist||""); color:"#aaa2b5"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11 }
            }
            Text { width:parent.width*.38; horizontalAlignment:Text.AlignRight; text:String(root.model.media?.position||"00:00")+" / "+String(root.model.media?.duration||"00:00"); color:"#62d8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:14; font.bold:true }
          }
        }
        Column { width:parent.width; spacing:7
          Text { text:"OPERATIONS LOG // DETERMINISTIC BUFFER"; color:root.model.accent; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; font.bold:true }
          Repeater { model:root.model.operation_log||[]; delegate:Text { required property var modelData; text:"--:--:--   DEMO   "+String(modelData); color:"#aaa2b5"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11 } }
        }
        Item { width:1; height:1 }
        Row { width:parent.width
          Text { width:parent.width*.7; text:"SCENARIO "+String((root.model.scenario_index||0)+1).padStart(2,"0")+" / "+String(root.model.scenario_count||0).padStart(2,"0")+"  ·  MAGI MENU → DEMONSTRATION MODE"; color:"#aaa2b5"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11 }
          Text { width:parent.width*.3; horizontalAlignment:Text.AlignRight; text:"CAPTURE SAFE // METADATA STRIPPED"; color:root.model.accent; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; font.bold:true }
        }
      }
    }
  }
}
