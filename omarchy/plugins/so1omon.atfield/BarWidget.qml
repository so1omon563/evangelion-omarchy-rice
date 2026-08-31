import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "so1omon.atfield"
  property bool fieldActive: false

  visible: fieldActive
  implicitWidth: fieldActive ? row.implicitWidth + Style.space(14) : 0
  implicitHeight: barSize

  function refresh() {
    if (!probe.running) probe.running = true
  }

  Process {
    id: probe
    running: true
    command: ["bash", "-c", "[[ -f $HOME/.local/state/evangelion-rice/at-field/active ]] && echo active || echo inactive"]
    stdout: SplitParser { onRead: function(line) { root.fieldActive = String(line).trim() === "active" } }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/evangelion-rice/at-field"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(5)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰭟"
      color: "#F6A52F"
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "A.T. FIELD // ACTIVE"
      color: "#FFD166"
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.5
      visible: !root.bar.vertical
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.bar.run("magi-focus off")
    onEntered: root.bar.showTooltip(root, "Release AT Field and restore notifications")
    onExited: root.bar.hideTooltip(root)
  }
}
