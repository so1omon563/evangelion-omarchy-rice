import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "../evangelion.motion" as Motion

BarWidget {
  id: root
  moduleName: "evangelion.mission"
  property bool popupOpen: false
  property var status: ({ phase: "sortie", label: "SORTIE", display: "00:00", cycle: 0, running: false, paused: false, remaining: 0, total: 0, config: ({ cycles: 4, work_minutes: 25, break_minutes: 5, long_break_minutes: 15, sound: true }) })
  readonly property bool active: status.phase === "work" || status.phase === "recovery"
  readonly property color stateColor: status.phase === "work" ? Color.accent : (status.phase === "recovery" ? "#F6D447" : root.bar.barForeground)
  readonly property string glyph: status.paused ? "󰏤" : (status.phase === "work" ? "󰐊" : (status.phase === "recovery" ? "󰒲" : (status.phase === "complete" ? "󰄬" : "󰔛")))

  function refresh() { if (!probe.running) probe.running = true }
  function action(name) { root.bar.run("magi-mission " + name); actionRefresh.restart() }
  function togglePopup() { popupOpen = !popupOpen; if (popupOpen) refresh() }
  function close() { popupOpen = false }

  implicitWidth: barRow.implicitWidth + Style.space(12)
  implicitHeight: barSize

  Process {
    id: probe
    running: true
    command: ["magi-mission", "status", "--json"]
    stdout: SplitParser { onRead: function(line) { try { root.status = JSON.parse(String(line)) } catch (e) {} } }
  }
  Timer { interval: root.active ? 1000 : 5000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { id: actionRefresh; interval: 350; repeat: false; onTriggered: root.refresh() }

  IpcHandler {
    target: "magi-mission"
    function toggle(): string { root.togglePopup(); return root.popupOpen ? "open" : "closed" }
    function open(): string { root.popupOpen = true; root.refresh(); return "open" }
    function close(): string { root.close(); return "closed" }
    function refresh(): string { root.refresh(); return "ok" }
  }

  Row {
    id: barRow
    anchors.centerIn: parent
    spacing: Style.space(5)
    Text { text: root.glyph; color: root.stateColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
    Text {
      text: root.active ? (root.status.paused ? "PAUSED // " : (root.status.phase === "work" ? "MISSION // " : "RECOVERY // ")) + root.status.display : root.status.label
      visible: !root.bar.vertical && root.bar.width >= 1600
      color: root.stateColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.action("toggle")
      else if (mouse.button === Qt.RightButton) root.action("abort")
      else root.togglePopup()
    }
  }

  Motion.MotionPopupCard {
    anchorItem: root; bar: root.bar; owner: root; open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(350)); contentHeight: fittedContentHeight(panel.implicitHeight)
    Column {
      id: panel
      anchors.fill: parent
      spacing: Style.space(9)
      Text { text: "MAGI // MISSION CLOCK"; color: Color.accent; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { text: root.status.paused ? "MISSION SUSPENDED" : root.status.label; color: root.stateColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.heading; font.bold: true }
      Text { text: root.active ? root.status.display : "READY"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.displayLarge; font.bold: true }
      Text { text: "CYCLE " + Math.min(root.status.cycle + 1, root.status.config.cycles) + " / " + root.status.config.cycles + "  ·  " + root.status.config.work_minutes + "M SORTIE  ·  " + root.status.config.break_minutes + "M RECOVERY"; color: Qt.darker(root.bar.foreground, 1.3); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }

      Rectangle {
        width: parent.width; height: Style.space(5); color: Color.muted; opacity: 0.35
        Rectangle { height: parent.height; width: root.status.total > 0 ? parent.width * Math.max(0, Math.min(1, 1 - root.status.remaining / root.status.total)) : 0; color: root.stateColor }
      }
      Rectangle { width: parent.width; height: 1; color: Color.muted; opacity: 0.45 }
      Row {
        width: parent.width; spacing: Style.space(7)
        Repeater {
          model: [
            { label: root.active ? (root.status.paused ? "RESUME" : "PAUSE") : "SORTIE", action: root.active ? "toggle" : "start" },
            { label: "ADVANCE", action: "skip" },
            { label: "ABORT", action: "abort" }
          ]
          delegate: BorderSurface {
            required property var modelData
            width: (panel.width - Style.space(14)) / 3; height: Style.space(36)
            color: Style.normalFillFor(root.bar.foreground, modelData.action === "abort" ? root.bar.urgent : Color.accent)
            borderSpec: Border.controlSpec("normal", root.bar.foreground, modelData.action === "abort" ? root.bar.urgent : Color.accent)
            Text { anchors.centerIn: parent; text: modelData.label; color: modelData.action === "abort" ? root.bar.urgent : root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.action(modelData.action) }
          }
        }
      }
      Text { text: "MIDDLE CLICK // PAUSE OR RESUME     RIGHT CLICK // ABORT"; color: Qt.darker(root.bar.foreground, 1.5); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
    }
  }
}
