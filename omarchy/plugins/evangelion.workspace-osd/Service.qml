import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id: root

  property var shell: null
  property bool initialized: false
  property bool opened: false
  property bool enabled: true
  Motion.MotionState { id: motion }
  readonly property bool reducedMotion: !motion.full
  property int lastWorkspaceId: -1
  property int showCount: 0
  property string heading: "MAGI // AUXILIARY"
  property string channel: "UNCLASSIFIED OPERATIONS CHANNEL"
  readonly property var targetScreen: {
    var focused = Hyprland.focusedMonitor
    var screens = Quickshell.screens || []
    if (focused) for (var i = 0; i < screens.length; i++) if (screens[i].name === focused.name) return screens[i]
    return screens.length ? screens[0] : null
  }

  function workspaceCopy(id) {
    var entries = {
      1: ["MELCHIOR // ANALYSIS", "MAGI-01 · LOGIC CHANNEL"],
      2: ["BALTHASAR // OPERATIONS", "MAGI-02 · HUMAN FACTOR"],
      3: ["CASPER // COMMUNICATIONS", "MAGI-03 · STRATEGIC LINK"],
      4: ["ENTRY PLUG // DEVELOPMENT", "EVA INTERFACE · BUILD CHANNEL"],
      5: ["TERMINAL // COMMAND", "NERV OPERATIONS · CONTROL CHANNEL"]
    }
    return entries[id] || ["WORKSPACE " + String(id).padStart(2, "0") + " // AUXILIARY",
                           "UNCLASSIFIED OPERATIONS CHANNEL"]
  }

  function showWorkspace(id, countTransition) {
    if (!root.enabled || id <= 0) return
    var copy = workspaceCopy(id)
    root.heading = copy[0]
    root.channel = copy[1]
    if (countTransition) root.showCount++
    root.opened = true
    retireTimer.restart()
  }

  function observeWorkspace() {
    var workspace = Hyprland.focusedWorkspace
    if (!workspace || workspace.id <= 0) return
    var id = workspace.id
    if (!root.initialized) {
      root.lastWorkspaceId = id
      root.initialized = true
      return
    }
    if (id === root.lastWorkspaceId) return
    root.lastWorkspaceId = id
    root.showWorkspace(id, true)
  }

  function refreshPreferences() {
    if (!preferenceProbe.running) preferenceProbe.running = true
  }

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() { root.observeWorkspace() }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/evangelion-rice/workspace-osd"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshPreferences()
  }

  Process {
    id: preferenceProbe
    running: true
    command: ["bash", "-c", "[[ -e $HOME/.local/state/evangelion-rice/workspace-osd/disabled ]] && echo yes || echo no"]
    stdout: SplitParser {
      onRead: function(line) {
        root.enabled = String(line).trim() !== "yes"
        if (!root.enabled) {
          root.opened = false
          retireTimer.stop()
        }
      }
    }
  }

  Timer {
    id: retireTimer
    interval: motion.full ? 780 : 900
    repeat: false
    onTriggered: root.opened = false
  }

  IpcHandler {
    target: "workspace-osd"
    function preview(workspace: int): string {
      root.showWorkspace(workspace > 0 ? workspace : 1, false)
      return root.heading
    }
    function hide(): string {
      root.opened = false
      retireTimer.stop()
      return "hidden"
    }
    function reload(): string {
      root.refreshPreferences()
      return "reloading"
    }
    function state(): string {
      return JSON.stringify({
        visible: root.opened,
        enabled: root.enabled,
        motionMode: motion.mode,
        workspace: root.lastWorkspaceId,
        showCount: root.showCount,
        heading: root.heading,
        timeoutMs: retireTimer.interval
      })
    }
  }

  Component.onCompleted: Qt.callLater(root.observeWorkspace)

  PanelWindow {
    screen: root.targetScreen
    visible: root.opened
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "magi-workspace-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      id: card
      width: Math.min(510, parent.width - 32, Math.max(280, parent.width * 0.44))
      height: 126
      anchors.left: parent.left
      anchors.leftMargin: Math.min(Math.max(16, parent.width * 0.055), (parent.width - width) / 2)
      anchors.verticalCenter: parent.verticalCenter
      radius: 3
      color: "#ed080710"
      border.width: 2
      border.color: "#9cf23a"
      opacity: root.opened ? 1 : 0

      Behavior on opacity {
        enabled: !motion.off
        NumberAnimation { duration: motion.standardMs; easing.type: Easing.OutCubic }
      }

      Rectangle {
        width: 8
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: "#7b2cbf"
      }

      Rectangle {
        width: 68
        height: 3
        anchors { top: parent.top; right: parent.right }
        anchors.topMargin: 13
        anchors.rightMargin: 15
        color: "#f6a52f"
      }

      Column {
        anchors {
          left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
          leftMargin: 31; rightMargin: 24
        }
        spacing: 10

        Text {
          width: parent.width
          text: root.heading
          color: "#9cf23a"
          elide: Text.ElideRight
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 20
          font.bold: true
          font.letterSpacing: 1.2
        }

        Rectangle { width: parent.width; height: 1; color: "#7450a6" }

        Row {
          spacing: 10
          Rectangle {
            width: 8; height: 8; radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: "#f6a52f"
          }
          Text {
            text: root.channel
            color: "#eee8ff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 0.7
          }
        }
      }
    }
  }
}
