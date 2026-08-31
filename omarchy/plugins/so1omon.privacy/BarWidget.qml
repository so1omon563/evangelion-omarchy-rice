import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "so1omon.privacy"
  property bool popupOpen: false
  property var status: ({ active: false, active_count: 0, summary: "CLEAR", states: ({}), suppressed: false, recording: ({ path: "", seconds: 0 }) })

  readonly property color alertColor: root.bar.urgent
  readonly property var stateOrder: ["microphone", "camera", "screen", "recording", "remote"]
  readonly property var stateLabels: ({ microphone: "MICROPHONE", camera: "CAMERA", screen: "SCREEN SHARE", recording: "RECORDING", remote: "REMOTE CONTROL" })

  function close() { popupOpen = false }
  function refresh() { if (!probe.running) probe.running = true }
  function togglePopup() { popupOpen = !popupOpen; if (popupOpen) refresh() }
  function respond(kind) { root.bar.run("magi-privacy stop " + kind); responseRefresh.restart() }
  function clientLine(kind) {
    var item = root.status.states && root.status.states[kind]
    return item && item.clients && item.clients.length ? item.clients.join(", ") : "CLIENT NOT EXPOSED"
  }
  function stateActive(kind) {
    if (!root.status.states) return false
    var item = root.status.states[kind]
    if (!item) return false
    return item.active === true
  }
  function activeCount() {
    var count = 0
    for (var i = 0; i < root.stateOrder.length; i++) if (root.stateActive(root.stateOrder[i])) count++
    return count
  }

  visible: status.active && !status.suppressed
  implicitWidth: alertRow.implicitWidth + Style.space(14)
  implicitHeight: barSize

  Process {
    id: probe
    running: true
    command: ["magi-privacy", "status", "--json"]
    stdout: SplitParser { onRead: function(line) { try { root.status = JSON.parse(String(line)) } catch (e) {} } }
  }

  Timer { interval: root.status.active || root.popupOpen ? 2000 : 7000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { id: responseRefresh; interval: 700; repeat: false; onTriggered: root.refresh() }

  IpcHandler {
    target: "magi-privacy"
    function toggle(): string { root.togglePopup(); return root.popupOpen ? "open" : "closed" }
    function open(): string { root.popupOpen = true; root.refresh(); return "open" }
    function close(): string { root.close(); return "closed" }
    function refresh(): string { root.refresh(); return "ok" }
    function suppress(): string { root.status.suppressed = true; root.statusChanged(); return "suppressed" }
    function restore(): string { root.status.suppressed = false; root.statusChanged(); root.refresh(); return "visible" }
  }

  Rectangle { anchors.fill: parent; color: root.alertColor; opacity: 0.18; border.color: root.alertColor; border.width: 1 }
  Row {
    id: alertRow
    anchors.centerIn: parent
    spacing: Style.space(5)
    Text { text: "󰒃"; color: root.alertColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
    Text { text: root.status.active_count > 2 ? "PRIVACY // " + root.status.active_count + " ACTIVE" : "PRIVACY // " + root.status.summary; visible: !root.bar.vertical; color: root.alertColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 0.5 }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.respond("all")
      else if (mouse.button === Qt.RightButton) root.bar.run("omarchy-launch-terminal -- bash -lc 'magi-privacy status; echo; read -rp \"Press Enter to close...\"'")
      else root.togglePopup()
    }
  }

  PopupCard {
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(390))
    contentHeight: fittedContentHeight(panel.implicitHeight)

    Column {
      id: panel
      anchors.fill: parent
      spacing: Style.space(9)

      Text { text: "NERV // PRIVACY ACTIVITY"; color: root.alertColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { text: root.status.active ? "CAPTURE CHANNEL ACTIVE" : "ALL CHANNELS CLEAR"; color: root.status.active ? root.alertColor : Color.accent; font.family: root.bar.fontFamily; font.pixelSize: Style.font.heading; font.bold: true }
      Rectangle { width: parent.width; height: 1; color: root.status.active ? root.alertColor : Color.muted; opacity: 0.65 }

      Repeater {
        model: root.stateOrder
        delegate: Column {
          required property string modelData
          width: panel.width
          visible: root.stateActive(modelData)
          spacing: Style.space(2)
          Text { text: "● " + root.stateLabels[parent.modelData]; color: root.alertColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
          Text { width: parent.width; text: "RESPONSIBLE // " + root.clientLine(parent.modelData); color: Qt.darker(root.bar.foreground, 1.25); wrapMode: Text.Wrap; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
        }
      }

      Text { visible: root.stateActive("recording"); width: parent.width; text: "ELAPSED // " + Math.floor(root.status.recording.seconds / 60).toString().padStart(2, "0") + ":" + (root.status.recording.seconds % 60).toString().padStart(2, "0") + (root.status.recording.path ? "\nOUTPUT // " + root.status.recording.path : ""); wrapMode: Text.Wrap; color: root.alertColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }

      Text { visible: !root.status.active; text: "No microphone, camera, sharing, recording, or remote-control activity detected."; width: parent.width; wrapMode: Text.Wrap; color: Qt.darker(root.bar.foreground, 1.25); font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
      Rectangle { width: parent.width; height: 1; color: Color.muted; opacity: 0.4 }

      Row {
        width: parent.width
        spacing: Style.space(8)
        BorderSurface {
          width: (panel.width - Style.space(8)) / 2; height: Style.space(36)
          color: Style.normalFillFor(root.bar.foreground, root.alertColor); borderSpec: Border.controlSpec("normal", root.bar.foreground, root.alertColor)
          Text { anchors.centerIn: parent; text: "SAFE RESPONSE"; color: root.alertColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.respond("all") }
        }
        BorderSurface {
          width: (panel.width - Style.space(8)) / 2; height: Style.space(36)
          color: Style.normalFillFor(root.bar.foreground, Color.accent); borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
          Text { anchors.centerIn: parent; text: "TERMINAL INSPECT"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.bar.run("omarchy-launch-terminal -- bash -lc 'magi-privacy status; echo; read -rp \"Press Enter to close...\"'") }
        }
      }
      Text { width: parent.width; text: "Response mutes the mic and stops known recorder/remote services. Close the named app to end camera or portal sharing."; wrapMode: Text.Wrap; color: Qt.darker(root.bar.foreground, 1.45); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
    }
  }
}
