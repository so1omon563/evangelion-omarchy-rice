import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id: root
  property var shell: null
  property bool active: false
  property bool previewActive: false
  property bool expanded: false
  Motion.MotionState { id: motion }
  readonly property bool reducedMotion: !motion.full
  readonly property bool displayed: root.active || root.previewActive
  readonly property var targetScreen: {
    var focused = Hyprland.focusedMonitor
    var screens = Quickshell.screens || []
    if (focused) for (var i = 0; i < screens.length; i++) if (screens[i].name === focused.name) return screens[i]
    return screens.length ? screens[0] : null
  }

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

  Process {
    id: probe
    running: true
    command: ["bash", "-c", "[[ -e $HOME/.local/state/evangelion-rice/angel-intrusion/active ]] && echo yes || echo no"]
    stdout: SplitParser {
      onRead: function(line) {
        var nextActive = String(line).trim() === "yes"
        if (nextActive && !root.active) root.enter(false)
        else if (!nextActive && root.active) root.leave()
      }
    }
  }

  Timer {
    id: collapseTimer
    interval: motion.full ? 3200 : 3600
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
        expanded:root.expanded,motionMode:motion.mode})
    }
  }

  PanelWindow {
    id: panel
    visible: root.displayed
    screen: root.targetScreen
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "angel-intrusion"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      id: card
      width: root.expanded ? Math.min(580, panel.width - 32, Math.max(280, panel.width * 0.46)) : Math.min(318, panel.width - 24)
      height: root.expanded ? Math.min(238, panel.height - 48) : 42
      x: root.expanded ? Math.min(Math.max(16, panel.width * 0.055), (panel.width - width) / 2) : panel.width - width - 12
      y: root.expanded ? (panel.height - height) / 2 : 46
      radius: 3
      color: "#f20b0508"
      border.width: 2
      border.color: "#ff153d"
      clip: true

      // Critical alerts are immediate in every motion mode. The dwell/collapse
      // remains long enough to read and use the documented safe-exit action.

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
