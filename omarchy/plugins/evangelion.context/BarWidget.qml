import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "../evangelion.motion" as Motion
import "../evangelion.localization" as Localization

BarWidget {
  id: root
  moduleName: "evangelion.context"
  property string accessibleName: "MAGI context, " + statusTitle()
  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Accessible.description: "Open contextual status, evidence, and recommendations"
  property bool popupOpen: false
  Localization.I18n { id:i18n }
  property var context: ({
    derived_state: ({ status: "unknown", summary: "No context has been published", freshness: ({ status: "unknown" }) }),
    signals: ({}), reasons: [], recommendations: [], automatic_actions: [],
    policy_state: ({ suppressed_reason_codes: [] }), controller: ({ automation_enabled: false })
  })
  readonly property string status: String(context.derived_state?.status || "unknown")
  readonly property string freshness: String(context.derived_state?.freshness?.status || "unknown")
  readonly property bool decorative: context.controller?.decorative_enabled !== false && freshness === "fresh"
  readonly property color stateColor: !decorative ? Color.muted : status === "critical" ? root.bar.urgent
    : (status === "constrained" || status === "offline" ? "#F6D447"
    : (status === "unknown" || status === "unavailable" || status === "disabled" ? Color.muted : Color.accent))
  readonly property var safeFacts: ["battery_percent", "connectivity", "display_mode", "media_state", "operating_profile", "power_source", "profile_selection", "temperature_c", "thermal_pressure", "time_band", "weekend"]
  readonly property var signalNames: ["power", "thermal", "displays", "devices", "connectivity", "media", "time", "operating_profile"]

  function close() { popupOpen = false }
  function read() { if (!statusProbe.running && !refreshProbe.running) statusProbe.running = true }
  function refresh() { if (!refreshProbe.running) refreshProbe.running = true }
  function togglePopup() { popupOpen = !popupOpen; if (popupOpen) refresh() }
  function accept(line) { try { context = JSON.parse(String(line)) } catch (error) {} }
  function reason() { return context.reasons?.length ? context.reasons[0] : ({ code:"awaiting-observations", summary:"No observations are available", facts:({}), signals:[] }) }
  function factRows() {
    var value = reason().facts || ({}), rows = []
    for (var i = 0; i < safeFacts.length; ++i) {
      var key = safeFacts[i]
      if (value[key] !== undefined && value[key] !== null) rows.push({ key:key, value:String(value[key]) })
    }
    return rows
  }
  function signalRows() {
    var rows = []
    for (var i = 0; i < signalNames.length; ++i) {
      var name = signalNames[i], item = context.signals?.[name] || ({})
      rows.push({ name:name, availability:String(item.availability || "unknown"), freshness:String(item.freshness?.status || "unknown") })
    }
    return rows
  }
  function safeRecommendations() {
    var rows = [], values = context.recommendations || []
    for (var i = 0; i < values.length; ++i) {
      var item = values[i]
      if (item?.action === "select-operating-profile" && ["docked", "mobile"].indexOf(item.target) >= 0)
        rows.push({ action:"select-operating-profile", target:item.target })
    }
    return rows
  }
  function runRecommendation(item) {
    if (!item || item.action !== "select-operating-profile" || ["docked", "mobile"].indexOf(item.target) < 0) return
    root.close()
    root.bar.run("magi-operating-profile " + item.target)
  }
  function statusTitle() {
    if (status === "unknown") return i18n.tr("context.unknown").toUpperCase()
    if (status === "unavailable") return i18n.tr("context.unavailable").toUpperCase()
    if (status === "disabled") return i18n.tr("context.disabled").toUpperCase()
    return i18n.tr("status."+status).toUpperCase()
  }
  function automationLabel() {
    var selected = String(reason().facts?.profile_selection || "")
    if (selected === "docked" || selected === "mobile") return i18n.tr("context.automation.manual").toUpperCase()
    if (!context.controller?.automation_enabled) return i18n.tr("context.automation.disabled").toUpperCase()
    return i18n.tr((context.automatic_actions || []).length?"context.automation.queued":"context.automation.armed").toUpperCase()
  }

  onPopupOpenChanged: if (popupOpen) Qt.callLater(function() { panelFocus.forceActiveFocus() })
  implicitWidth: Style.space(28)
  implicitHeight: barSize

  Process { id: statusProbe; command:["magi-context","status","--json","--compact"]; stdout:SplitParser { onRead:function(line) { root.accept(line) } } }
  Process { id: refreshProbe; command:["magi-context","refresh","--json","--compact"]; stdout:SplitParser { onRead:function(line) { root.accept(line) } } }
  Component.onCompleted: read()
  IpcHandler {
    target: "magi-context-inspector"
    function toggle(): string { root.togglePopup(); return root.popupOpen ? "open" : "closed" }
    function open(): string { root.popupOpen = true; root.refresh(); return "open" }
    function close(): string { root.close(); return "closed" }
    function refresh(): string { root.refresh(); return "ok" }
  }

  Text { anchors.centerIn:parent; text:"󰘦"; color:root.stateColor; font.family:root.bar.fontFamily; font.pixelSize:Style.font.body; font.bold:true }
  Motion.StateCue {
    anchors { left:parent.left; top:parent.top; bottom:parent.bottom }
    active:root.decorative&&(status==="critical"||status==="constrained"||status==="offline")
    critical:status==="critical"
    cueColor:root.stateColor
  }
  MouseArea {
    anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
    onClicked:root.togglePopup()
    onEntered:root.bar.showTooltip(root,"MAGI CONTEXT // "+root.statusTitle()+" · "+root.freshness.toUpperCase())
    onExited:root.bar.hideTooltip(root)
  }

  Motion.MotionPopupCard {
    anchorItem:root; bar:root.bar; owner:root; open:root.popupOpen; centerOnBar:true
    contentWidth:fittedContentWidth(Style.space(510)); contentHeight:fittedContentHeight(Math.min(contentColumn.implicitHeight,Style.space(650)))

    FocusScope {
      id:panelFocus; anchors.fill:parent
      Keys.onEscapePressed:root.close()
      Flickable {
        anchors.fill:parent; contentWidth:width; contentHeight:contentColumn.implicitHeight; clip:true
        boundsBehavior:Flickable.StopAtBounds; flickableDirection:Flickable.VerticalFlick
        Column {
          id:contentColumn; width:parent.width; spacing:Style.space(8)
          LayoutMirroring.enabled:i18n.rtl
          LayoutMirroring.childrenInherit:true
          Text { text:i18n.tr("context.inspector").toUpperCase(); color:Color.accent; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true; font.letterSpacing:1 }
          Text { text:root.statusTitle(); color:root.stateColor; font.family:root.bar.fontFamily; font.pixelSize:Style.font.heading; font.bold:true }
          Text { width:parent.width; text:String(root.context.derived_state?.summary || "No context has been published"); wrapMode:Text.Wrap; color:root.bar.foreground; font.family:root.bar.fontFamily; font.pixelSize:Style.font.body }
          Text { text:i18n.tr("context.freshness",{freshness:root.freshness,version:String(root.context.contract?.policy_version||"--")}).toUpperCase(); color:root.freshness==="stale"?"#F6D447":Qt.darker(root.bar.foreground,1.35); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
          Rectangle { width:parent.width; height:1; color:root.stateColor; opacity:.55 }

          Text { text:i18n.tr("context.conclusion",{code:String(root.reason().code||"unknown")}).toUpperCase(); color:root.stateColor; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
          Repeater { model:root.factRows(); delegate:Row { required property var modelData; width:contentColumn.width
            Text { width:parent.width*.48; text:String(modelData.key).replace(/_/g," ").toUpperCase(); color:Qt.darker(root.bar.foreground,1.35); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
            Text { width:parent.width*.52; text:String(modelData.value).toUpperCase(); elide:Text.ElideRight; color:root.bar.foreground; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
          } }
          Text { visible:root.factRows().length===0; text:i18n.tr("context.no_facts").toUpperCase(); color:Qt.darker(root.bar.foreground,1.35); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }

          Rectangle { width:parent.width; height:1; color:Color.muted; opacity:.35 }
          Text { text:i18n.tr("context.signals").toUpperCase(); color:Color.accent; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
          Grid { width:parent.width; columns:2; rowSpacing:Style.space(4); columnSpacing:Style.space(8)
            Repeater { model:root.signalRows(); delegate:Text { required property var modelData; width:(contentColumn.width-Style.space(8))/2; text:String(modelData.name).replace(/_/g," ").toUpperCase()+" // "+String(modelData.availability).toUpperCase()+" · "+String(modelData.freshness).toUpperCase(); elide:Text.ElideRight; color:modelData.freshness==="stale"?"#F6D447":Qt.darker(root.bar.foreground,1.25); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption } }
          }

          Rectangle { width:parent.width; height:1; color:Color.muted; opacity:.35 }
          Text { text:i18n.tr("context.suppressed").toUpperCase(); color:Color.accent; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
          Text { width:parent.width; text:(root.context.policy_state?.suppressed_reason_codes || []).length ? root.context.policy_state.suppressed_reason_codes.join("  ·  ").toUpperCase() : "NONE"; wrapMode:Text.Wrap; color:Qt.darker(root.bar.foreground,1.3); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }

          Rectangle { width:parent.width; height:1; color:Color.muted; opacity:.35 }
          Text { text:i18n.tr("context.recommended",{count:root.safeRecommendations().length}).toUpperCase(); color:Color.accent; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
          Text { visible:root.safeRecommendations().length===0; text:i18n.tr("context.no_action").toUpperCase(); color:Qt.darker(root.bar.foreground,1.35); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
          Repeater { model:root.safeRecommendations(); delegate:BorderSurface {
            required property var modelData; width:contentColumn.width; height:Style.space(42); activeFocusOnTab:true
            color:Style.normalFillFor(root.bar.foreground,Color.accent); borderSpec:Border.controlSpec(activeFocus?"focus":"normal",root.bar.foreground,Color.accent)
            Text { anchors.centerIn:parent; width:parent.width-Style.space(16); horizontalAlignment:Text.AlignHCenter; elide:Text.ElideRight; text:i18n.tr("context.apply",{target:String(modelData.target||"")}).toUpperCase(); color:root.bar.foreground; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:root.runRecommendation(modelData) }
            Keys.onPressed:function(event){ if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter||event.key===Qt.Key_Space){ root.runRecommendation(modelData); event.accepted=true } }
          } }

          Row { width:parent.width; spacing:Style.space(8)
            BorderSurface { id:refreshButton; width:(parent.width-Style.space(8))/2; height:Style.space(38); activeFocusOnTab:true; focus:true; color:Style.normalFillFor(root.bar.foreground,Color.accent); borderSpec:Border.controlSpec(activeFocus?"focus":"normal",root.bar.foreground,Color.accent)
              Text { anchors.centerIn:parent; width:parent.width-Style.space(12); horizontalAlignment:Text.AlignHCenter; elide:Text.ElideRight; text:i18n.tr("context.refresh").toUpperCase(); color:root.bar.foreground; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
              MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:root.refresh() }
              Keys.onPressed:function(event){ if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter||event.key===Qt.Key_Space){ root.refresh(); event.accepted=true } }
            }
            BorderSurface { width:(parent.width-Style.space(8))/2; height:Style.space(38); activeFocusOnTab:true; color:Style.normalFillFor(root.bar.foreground,Color.accent); borderSpec:Border.controlSpec(activeFocus?"focus":"normal",root.bar.foreground,Color.accent)
              Text { anchors.centerIn:parent; width:parent.width-Style.space(12); horizontalAlignment:Text.AlignHCenter; elide:Text.ElideRight; text:i18n.tr("context.close").toUpperCase(); color:root.bar.foreground; font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption; font.bold:true }
              MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:root.close() }
              Keys.onPressed:function(event){ if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter||event.key===Qt.Key_Space){ root.close(); event.accepted=true } }
            }
          }
          Text { width:parent.width; elide:Text.ElideRight; text:i18n.tr("context.automation",{state:root.automationLabel(),count:String((root.context.automatic_actions||[]).length)}).toUpperCase(); color:Qt.darker(root.bar.foreground,1.4); font.family:root.bar.fontFamily; font.pixelSize:Style.font.caption }
        }
      }
    }
  }
}
