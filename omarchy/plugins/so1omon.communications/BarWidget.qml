import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "so1omon.communications"
  property bool popupOpen: false
  property var status: ({ link: "unknown", connectivity: "unknown", connection: "", type: "unknown", interface: "", gateway: "", ssid: "", signal: -1, vpn: "", bluetooth: "unavailable", bluetoothDevices: 0, tailscale: "unavailable", tailscalePeers: 0, tailscaleName: "" })

  readonly property string glyph: status.link === "online" ? "󰖩" : (status.link === "limited" || status.link === "local" ? "󰖪" : "󰖟")
  readonly property color stateColor: status.link === "online" ? Color.accent : (status.link === "offline" ? root.bar.urgent : "#F6D447")
  readonly property string barLabel: "COMM // " + String(status.link || "unknown").toUpperCase()

  function close() { popupOpen = false }
  function refresh() { if (!probe.running) probe.running = true }
  function togglePopup() { popupOpen = !popupOpen; if (popupOpen) refresh() }
  function openControl(target) {
    popupOpen = false
    root.bar.run("omarchy-shell shell toggle " + target)
  }

  implicitWidth: row.implicitWidth + Style.space(12)
  implicitHeight: barSize

  Process {
    id: probe
    running: true
    command: ["magi-communications", "--json"]
    stdout: SplitParser {
      onRead: function(line) {
        try { root.status = JSON.parse(String(line)) } catch (e) { }
      }
    }
  }

  Timer {
    interval: root.popupOpen ? 5000 : 15000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "magi-communications"
    function toggle(): string { root.togglePopup(); return root.popupOpen ? "open" : "closed" }
    function open(): string { root.popupOpen = true; root.refresh(); return "open" }
    function close(): string { root.close(); return "closed" }
    function refresh(): string { root.refresh(); return "ok" }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(5)
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.glyph; color: root.stateColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.barLabel; color: root.bar.barForeground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; visible: !root.bar.vertical }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { if (mouse.button === Qt.LeftButton) root.togglePopup(); else root.openControl("omarchy.network") }
    onEntered: root.bar.showTooltip(root, root.barLabel + " · click for communication telemetry")
    onExited: root.bar.hideTooltip(root)
  }

  PopupCard {
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(360))
    contentHeight: fittedContentHeight(panel.implicitHeight)

    Column {
      id: panel
      anchors.fill: parent
      spacing: Style.space(9)

      Text { text: "NERV // COMMUNICATION LINK"; color: Color.accent; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
      Text { text: root.status.link === "online" ? "ALL CHANNELS NOMINAL" : (root.status.link === "offline" ? "UPLINK UNAVAILABLE" : "DEGRADED CONNECTION"); color: root.stateColor; font.family: root.bar.fontFamily; font.pixelSize: Style.font.heading; font.bold: true }

      Rectangle { width: parent.width; height: 1; color: Color.muted; opacity: 0.55 }

      Text { text: "UPLINK // " + (root.status.connection || "NO ACTIVE CONNECTION"); color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
      Text { text: (root.status.type || "unknown").toUpperCase() + (root.status.signal >= 0 ? " · SIGNAL " + root.status.signal + "%" : "") + " · INTERNET " + String(root.status.connectivity || "unknown").toUpperCase(); color: Qt.darker(root.bar.foreground, 1.35); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
      Text { text: "ROUTE // " + (root.status.interface || "--") + (root.status.gateway ? " VIA " + root.status.gateway : ""); color: Qt.darker(root.bar.foreground, 1.35); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }

      Rectangle { width: parent.width; height: 1; color: Color.muted; opacity: 0.35 }

      Text { text: "ENCRYPTED LINK // " + (root.status.vpn ? root.status.vpn : (root.status.tailscale === "on" ? "TAILSCALE" : "NONE")); color: root.status.vpn || root.status.tailscale === "on" ? Color.accent : Qt.darker(root.bar.foreground, 1.5); font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
      Text { text: "TAILSCALE " + String(root.status.tailscale || "unavailable").toUpperCase() + " · " + root.status.tailscalePeers + " PEERS"; color: Qt.darker(root.bar.foreground, 1.35); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
      Text { text: "LOCAL RADIO // BLUETOOTH " + String(root.status.bluetooth || "unavailable").toUpperCase() + " · " + root.status.bluetoothDevices + " DEVICES"; color: Qt.darker(root.bar.foreground, 1.35); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }

      Rectangle { width: parent.width; height: 1; color: Color.muted; opacity: 0.35 }

      Row {
        width: parent.width
        spacing: Style.space(8)
        Repeater {
          model: [
            { label: "NETWORK", target: "omarchy.network" },
            { label: "BLUETOOTH", target: "omarchy.bluetooth" },
            { label: "TAILSCALE", target: "omarchy.tailscale" }
          ]
          delegate: BorderSurface {
            required property var modelData
            width: (panel.width - Style.space(16)) / 3
            height: Style.space(34)
            color: Style.normalFillFor(root.bar.foreground, Color.accent)
            borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
            Text { anchors.centerIn: parent; text: modelData.label; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.openControl(modelData.target) }
          }
        }
      }
    }
  }
}
