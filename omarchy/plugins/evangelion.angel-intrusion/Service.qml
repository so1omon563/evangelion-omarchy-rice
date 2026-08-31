import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root
  property var shell: null
  property bool active: false
  property bool previewActive: false
  property bool expanded: false
  property bool reducedMotion: false
  readonly property bool displayed: root.active || root.previewActive

  function enter(preview) {
    if (preview) root.previewActive = true
    else root.active = true
    root.expanded = true
    collapseTimer.restart()
  }

  function leave() {
    root.active = false
    root.previewActive = false
    root.expanded = false
    collapseTimer.stop()
  }

  function refresh() {
    if (!probe.running) probe.running = true
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/evangelion-rice/angel-intrusion"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/evangelion-screensaver.json"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Process {
    id: probe
    running: true
    command: ["bash", "-c", "active=no; reduced=no; [[ -e $HOME/.local/state/evangelion-rice/angel-intrusion/active ]] && active=yes; jq -e '.reduced_motion == true' $HOME/.config/omarchy/evangelion-screensaver.json >/dev/null 2>&1 && reduced=yes; printf '%s %s\\n' \"$active\" \"$reduced\""]
    stdout: SplitParser {
      onRead: function(line) {
        var fields = String(line).trim().split(" ")
        var nextActive = fields[0] === "yes"
        root.reducedMotion = fields[1] === "yes"
        if (nextActive && !root.active) root.enter(false)
        else if (!nextActive && root.active) root.leave()
      }
    }
  }

  Timer {
    id: collapseTimer
    interval: root.reducedMotion ? 1800 : 3200
    onTriggered: {
      if (root.previewActive) root.leave()
      else root.expanded = false
    }
  }

  IpcHandler {
    target: "angel-intrusion"
    function activate(): string { root.enter(false); return "active" }
    function deactivate(): string { root.leave(); return "inactive" }
    function preview(): string { root.enter(true); return "preview" }
    function state(): string {
      return JSON.stringify({active:root.active,preview:root.previewActive,
        expanded:root.expanded,reducedMotion:root.reducedMotion})
    }
  }

  PanelWindow {
    id: panel
    visible: root.displayed
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "angel-intrusion"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      id: card
      width: root.expanded ? Math.min(580, panel.width * 0.46) : 318
      height: root.expanded ? 238 : 42
      x: root.expanded ? Math.max(44, panel.width * 0.055) : panel.width - width - 22
      y: root.expanded ? (panel.height - height) / 2 : 46
      radius: 3
      color: "#f20b0508"
      border.width: 2
      border.color: "#ff153d"
      clip: true

      Behavior on width { enabled: !root.reducedMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on height { enabled: !root.reducedMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on x { enabled: !root.reducedMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !root.reducedMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Rectangle {
        width: 9
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: "#ff153d"
      }

      Row {
        visible: !root.expanded
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 24; rightMargin: 14 }
        spacing: 10
        Text { text: "󰀦"; color: "#f6a52f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17 }
        Text { text: "ANGEL PATTERN // BLUE"; color: "#ff4055"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 0.8 }
      }

      Column {
        visible: root.expanded
        anchors { fill: parent; leftMargin: 35; rightMargin: 27; topMargin: 24; bottomMargin: 20 }
        spacing: 10

        Text { text: "ANGEL PATTERN // BLUE"; color: "#ff153d"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 26; font.bold: true; font.letterSpacing: 1.8 }
        Rectangle { width: parent.width; height: 2; color: "#f6a52f" }
        Text { text: "NERV CENTRAL DOGMA  ·  SECURITY CONDITION ONE"; color: "#eee8ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
        Text { text: "UNIDENTIFIED SIGNAL DETECTED\nMAGI CONSENSUS: INTRUSION SIMULATION ACTIVE"; color: "#ff8a66"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true; lineHeight: 1.25 }
        Item { width: 1; height: 4 }
        Text { text: "MANUAL DEMONSTRATION  //  NO AUTOMATIC TRIGGER"; color: "#a794c7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.letterSpacing: 0.7 }
        Text { text: "SAFE EXIT  ›  magi-intrusion exit"; color: "#9cf23a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
      }
    }
  }
}
