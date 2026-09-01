import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id: root
  property bool enabled: false
  property var report: ({samples:0,event_changes:0,components:[],caches:[],privacy:{payload_capture:false}})
  property int renderEvents: 0
  readonly property var targetScreen: (Quickshell.screens || []).length ? Quickshell.screens[0] : null
  Motion.MotionState { id: motion }

  function refreshStatus() { if (!statusProbe.running) statusProbe.running=true }
  function sample() { if (root.enabled && !sampleProbe.running) sampleProbe.running=true }
  function accept(text) { try { root.report=JSON.parse(String(text)); root.enabled=root.report.enabled===true; root.renderEvents++ } catch(error) {} }
  function toggle() { if (!toggleProbe.running) toggleProbe.running=true }
  function component(index) { return root.report.components?.[index] || ({component:"awaiting",average_ms:0,maximum_ms:0,availability:"unknown"}) }

  FileView { path:Quickshell.env("HOME")+"/.config/omarchy/performance.json"; watchChanges:true; printErrors:false; onFileChanged:root.refreshStatus() }
  Process { id:statusProbe; running:true; command:["magi-performance","status","--json"]; stdout:StdioCollector { onStreamFinished:root.accept(text) } }
  Process { id:sampleProbe; command:["magi-performance","sample","--json"]; stdout:StdioCollector { onStreamFinished:root.accept(text) } }
  Process { id:toggleProbe; command:["magi-performance","toggle"]; onExited:root.refreshStatus() }
  Timer { interval:Math.max(1000,Number(root.report.sample_interval_ms||2000)); repeat:true; running:root.enabled; onTriggered:root.sample() }
  IpcHandler { target:"magi-performance-overlay"
    function toggle():string { root.toggle(); return "queued" }
    function refresh():string { root.sample(); return "queued" }
    function state():string { return JSON.stringify({enabled:root.enabled,motionMode:motion.mode,samples:root.report.samples,renderEvents:root.renderEvents}) }
  }

  PanelWindow {
    screen:root.targetScreen; visible:root.enabled
    anchors { top:true; right:true }
    margins { top:54; right:18 }
    implicitWidth:460; implicitHeight:Math.min(430,190+rows.implicitHeight)
    color:"transparent"; exclusionMode:ExclusionMode.Ignore; mask:Region {}
    WlrLayershell.namespace:"magi-performance"; WlrLayershell.layer:WlrLayer.Overlay; WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
    Rectangle {
      anchors.fill:parent; color:"#f2080710"; border.width:2; border.color:"#9cf23a"; radius:3
      opacity:root.enabled?1:0
      Behavior on opacity { enabled:!motion.off; NumberAnimation { duration:motion.full?180:80; easing.type:Easing.OutCubic } }
      Rectangle {
        width:7
        anchors.left:parent.left
        anchors.top:parent.top
        anchors.bottom:parent.bottom
        color:"#7b2cbf"
      }
      Column {
        id:rows
        anchors.left:parent.left
        anchors.right:parent.right
        anchors.top:parent.top
        anchors.margins:22
        spacing:9
        Text { text:"MAGI // DEVELOPER TELEMETRY"; color:"#9cf23a"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:15; font.bold:true; font.letterSpacing:1 }
        Text { text:"AGGREGATE ONLY  ·  PAYLOAD CAPTURE OFF"; color:"#f6a52f"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10; font.bold:true }
        Rectangle { width:parent.width; height:1; color:"#7450a6" }
        Row { spacing:18
          Text { text:"SAMPLES // "+String(root.report.samples||0); color:"#eee8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; font.bold:true }
          Text { text:"EVENT Δ // "+String(root.report.event_changes||0); color:"#55d9ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; font.bold:true }
          Text { text:"MOTION // "+motion.mode.toUpperCase(); color:"#f6a52f"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; font.bold:true }
        }
        Text { text:"EXPENSIVE COMPONENTS"; color:"#9cf23a"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; font.bold:true }
        Repeater { model:Math.min(6,(root.report.components||[]).length); delegate:Row {
          required property int index; width:rows.width
          property var item:root.component(index)
          Text { width:145; text:String(parent.item.component).toUpperCase(); elide:Text.ElideRight; color:"#eee8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11 }
          Text { width:110; text:"AVG "+Number(parent.item.average_ms||0).toFixed(2)+" MS"; color:"#55d9ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11 }
          Text { width:90; text:Number(parent.item.refresh_hz||0).toFixed(3)+" HZ"; color:"#9cf23a"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11 }
          Text { width:75; text:String(parent.item.availability||"unknown").toUpperCase(); elide:Text.ElideRight; color:Number(parent.item.maximum_ms||0)>250?"#ff4055":"#f6a52f"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10 }
        } }
        Text { text:"CACHE FRESHNESS"; color:"#9cf23a"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; font.bold:true }
        Repeater { model:root.report.caches||[]; delegate:Row {
          required property var modelData; width:rows.width
          Text { width:165; text:String(modelData.component).toUpperCase(); color:"#eee8ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10 }
          Text { text:modelData.age_seconds===null?"UNAVAILABLE":String(modelData.age_seconds)+" S OLD"; color:modelData.age_seconds!==null&&modelData.age_seconds>300?"#f6a52f":"#55d9ff"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10; font.bold:true }
        } }
        Rectangle { width:parent.width; height:1; color:"#7450a6" }
        Text { text:"POLL // "+String(root.report.sample_interval_ms||2000)+" MS  ·  ONE PROBE/CYCLE  ·  RENDER EVENTS // "+root.renderEvents; color:"#aaa2b5"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10 }
        Text { text:"SUPER + CTRL + ALT + F TO DISENGAGE"; color:"#9cf23a"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10; font.bold:true }
      }
    }
  }
}
