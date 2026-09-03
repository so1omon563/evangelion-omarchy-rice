import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "../evangelion.motion" as Motion
import "../evangelion.localization" as Localization

BarWidget {
  id: root
  moduleName: "evangelion.health"
  property string accessibleName: "System health, " + status.summary
  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Accessible.description: "Open health findings and safe remediation options"
  property bool popupOpen: false
  property var status: ({ level:"nominal", issues:0, summary:"NOMINAL", items:[] })
  property var riceStatus: ({ status:"unavailable", failures:0, findings:[], fixes:[] })
  Localization.I18n { id:i18n }
  readonly property color stateColor: status.level === "critical" ? root.bar.urgent : (status.level === "warning" ? "#F6D447" : Color.accent)
  function refresh() { if (!probe.running) probe.running=true; if (!riceProbe.running) riceProbe.running=true }
  function togglePopup() { popupOpen=!popupOpen; if (popupOpen) refresh() }
  function close() { popupOpen=false }
  function rowColor(tier) { return tier === "critical" ? root.bar.urgent : (tier === "warning" ? "#F6D447" : (tier === "info" ? Color.accent : root.bar.foreground)) }
  function terminal() { root.bar.run("omarchy-launch-terminal -- bash -lc 'magi-health status; echo; magi-rice-health diagnose; echo; read -rp \"Press Enter to close...\"'") }
  function remediation() { root.bar.run("omarchy-launch-terminal -- bash -lc 'magi-rice-health preview quarantine-stale-health-cache; echo; echo Apply only after reviewing the plan shown above.; read -rp \"Press Enter to close...\"'") }

  implicitWidth: barRow.implicitWidth + Style.space(10); implicitHeight: barSize
  Process { id: probe; running:true; command:["magi-health","status","--json"]; stdout:SplitParser { onRead:function(line) { try { root.status=JSON.parse(String(line)) } catch(e){} } } }
  Process { id: riceProbe; running:true; command:["magi-rice-health","diagnose","--json"]; stdout:SplitParser { onRead:function(line) { try { root.riceStatus=JSON.parse(String(line)) } catch(e){} } } }
  Timer { interval: root.status.issues > 0 || root.popupOpen ? 15000 : 45000; running:true; repeat:true; onTriggered:root.refresh() }
  IpcHandler { target:"magi-health"; function toggle():string { root.togglePopup(); return root.popupOpen?"open":"closed" } function open():string { root.popupOpen=true; root.refresh(); return "open" } function close():string { root.close(); return "closed" } function refresh():string { root.refresh(); return "ok" } }

  Row { id:barRow; anchors.centerIn:parent; spacing:Style.space(5)
    Text { text:root.status.issues>0?"󰀦":"󰄬"; color:root.stateColor; font.family:root.bar.fontFamily; font.pixelSize:Style.font.body; font.bold:true }
    Text { text:"SYSTEM // "+root.status.summary; visible:!root.bar.vertical && root.status.issues>0; color:root.stateColor; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
  }
  Motion.StateCue {
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    active: root.status.issues > 0
    critical: root.status.level === "critical" || root.status.level === "warning"
    cueColor: root.stateColor
  }
  MouseArea { anchors.fill:parent; acceptedButtons:Qt.LeftButton|Qt.RightButton; cursorShape:Qt.PointingHandCursor; onClicked:function(mouse){ if(mouse.button===Qt.RightButton) root.terminal(); else root.togglePopup() } }

  Motion.MotionPopupCard { anchorItem:root; bar:root.bar; owner:root; open:root.popupOpen; contentWidth:fittedContentWidth(Style.space(410)); contentHeight:fittedContentHeight(panel.implicitHeight)
    Column { id:panel; anchors.fill:parent; spacing:Style.space(8)
      Text { text:"NERV // SYSTEM HEALTH"; color:Color.accent; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true; font.letterSpacing:1 }
      Text { text:root.status.issues>0?"INTERVENTION REQUIRED":"ALL SYSTEMS NOMINAL"; color:root.stateColor; font.family:root.bar.fontFamily; font.pixelSize:Style.font.heading; font.bold:true }
      Text { text:i18n.tr("health.rice_integrity").toUpperCase()+" // "+String(root.riceStatus.status).toUpperCase()+"  ·  "+i18n.tr("health.findings",{count:String(root.riceStatus.failures||0)}).toUpperCase(); color:root.riceStatus.failures>0?"#F6D447":Color.accent; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
      Repeater { model:(root.riceStatus.findings||[]).filter(function(row){return row.status==="failed"}).slice(0,3)
        delegate:Text { required property var modelData; width:panel.width; text:String(modelData.category).toUpperCase()+" // "+modelData.summary; elide:Text.ElideRight; color:modelData.severity==="critical"?root.bar.urgent:"#F6D447"; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
      }
      Rectangle { width:parent.width; height:1; color:root.stateColor; opacity:.55 }
      Repeater { model:root.status.items
        delegate:Column { required property var modelData; width:panel.width; spacing:Style.space(2)
          Row { width:parent.width
            Text { width:Style.space(100); text:modelData.name; color:root.rowColor(modelData.tier); font.family:root.bar.fontFamily; font.pixelSize:Style.font.body; font.bold:true }
            Text { width:Style.space(62); text:modelData.value; color:root.rowColor(modelData.tier); font.family:root.bar.fontFamily; font.pixelSize:Style.font.body; font.bold:true }
            Text { width:parent.width-Style.space(162); text:modelData.detail; elide:Text.ElideRight; color:modelData.available?Qt.darker(root.bar.foreground,1.25):Qt.darker(root.bar.foreground,1.7); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
          }
          Text { visible:modelData.tier==="warning"||modelData.tier==="critical"; width:parent.width; text:"ACTION // "+modelData.action; color:root.rowColor(modelData.tier); wrapMode:Text.Wrap; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
        }
      }
      Rectangle { width:parent.width; height:1; color:Color.muted; opacity:.4 }
      Row { width:parent.width; spacing:Style.space(8)
        BorderSurface { width:(panel.width-Style.space(8))/2; height:Style.space(36); color:Style.normalFillFor(root.bar.foreground,Color.accent); borderSpec:Border.controlSpec("normal",root.bar.foreground,Color.accent); Text{anchors.centerIn:parent;text:"REFRESH";color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true} MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.refresh()} }
        BorderSurface { width:(panel.width-Style.space(8))/2; height:Style.space(36); color:Style.normalFillFor(root.bar.foreground,Color.accent); borderSpec:Border.controlSpec("normal",root.bar.foreground,Color.accent); Text{anchors.centerIn:parent;text:"TERMINAL INSPECT";color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true} MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.terminal()} }
      }
      BorderSurface { visible:(root.riceStatus.fixes||[]).length>0; width:panel.width; height:Style.space(32); color:Style.normalFillFor(root.bar.foreground,"#F6D447"); borderSpec:Border.controlSpec("normal",root.bar.foreground,"#F6D447"); Text{anchors.centerIn:parent;text:i18n.tr("health.preview_remediation").toUpperCase();color:"#F6D447";font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true} MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.remediation()} }
      Text { text:"NOMINAL POLL // 45S     ALERT POLL // 15S     UPDATE CACHE // 15M"; color:Qt.darker(root.bar.foreground,1.5); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
    }
  }
}
