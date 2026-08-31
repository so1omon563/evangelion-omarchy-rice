import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland

Item {
  id: root

  property var shell: null
  property bool opened: false
  property bool stayAwake: false

  readonly property var idleConfig: shell && shell.shellConfig && shell.shellConfig.idle
    ? shell.shellConfig.idle : ({})
  readonly property int statusTimeoutSeconds: validSeconds(idleConfig.status, 180)
  readonly property int screensaverTimeoutSeconds: validSeconds(idleConfig.screensaver, 300)
  readonly property int visibleSeconds: Math.max(1, screensaverTimeoutSeconds - statusTimeoutSeconds)
  readonly property int batteryPercent: UPower.displayDevice
    ? Math.round(UPower.displayDevice.percentage * 100) : -1
  readonly property string powerState: UPower.onBattery ? "INTERNAL RESERVE" : "UMBILICAL POWER"
  readonly property var targetScreen: {
    var focused = Hyprland.focusedMonitor
    var screens = Quickshell.screens || []
    if (focused) for (var i = 0; i < screens.length; i++) if (screens[i].name === focused.name) return screens[i]
    return screens.length ? screens[0] : null
  }

  function validSeconds(value, fallback) {
    var parsed = Number(value)
    return isFinite(parsed) && parsed > 0 ? Math.round(parsed) : fallback
  }

  function open() {
    if (root.stayAwake || root.statusTimeoutSeconds >= root.screensaverTimeoutSeconds) return
    root.opened = true
    retireTimer.restart()
  }

  function close() {
    root.opened = false
    retireTimer.stop()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake"
    watchChanges: true
    printErrors: false
    onLoaded: {
      root.stayAwake = true
      root.close()
    }
    onLoadFailed: root.stayAwake = false
    onFileChanged: reload()
  }

  IdleMonitor {
    enabled: !root.stayAwake
    timeout: root.statusTimeoutSeconds
    respectInhibitors: true
    onIsIdleChanged: {
      if (isIdle) root.open()
      else root.close()
    }
  }

  Timer {
    id: retireTimer
    interval: root.visibleSeconds * 1000
    onTriggered: root.opened = false
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  IpcHandler {
    target: "magi-idle"
    function show(): string {
      root.opened = true
      retireTimer.stop()
      return "visible"
    }
    function hide(): string {
      root.close()
      return "hidden"
    }
    function state(): string {
      return JSON.stringify({
        visible: root.opened,
        idle: idleMonitor.isIdle,
        stayAwake: root.stayAwake,
        status: root.statusTimeoutSeconds,
        screensaver: root.screensaverTimeoutSeconds
      })
    }
  }

  PanelWindow {
    screen: root.targetScreen
    visible: root.opened
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "magi-idle-status"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      width: Math.min(520, parent.width - 32, Math.max(280, parent.width * 0.42))
      height: Math.min(324, parent.height - 48)
      anchors.left: parent.left
      anchors.leftMargin: Math.min(Math.max(16, parent.width * 0.045), (parent.width - width) / 2)
      anchors.verticalCenter: parent.verticalCenter
      radius: 4
      color: "#e6080710"
      border.width: 2
      border.color: "#9cf23a"

      Rectangle {
        width: 7
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: "#7b2cbf"
      }

      Column {
        anchors {
          fill: parent
          leftMargin: 34
          rightMargin: 28
          topMargin: 25
          bottomMargin: 24
        }
        spacing: 11

        Text {
          text: "MAGI SYSTEM"
          color: "#9cf23a"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 27
          font.bold: true
          font.letterSpacing: 2
        }

        Rectangle { width: parent.width; height: 2; color: "#7b2cbf" }

        Text {
          text: Qt.formatDateTime(clock.date, "yyyy.MM.dd  HH:mm")
          color: "#eee8ff"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 20
          font.bold: true
        }

        Text {
          text: "MELCHIOR  ·  ONLINE\nBALTHASAR ·  ONLINE\nCASPER    ·  ONLINE"
          color: "#9cf23a"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
          font.letterSpacing: 1
          lineHeight: 1.25
        }

        Item { width: 1; height: 4 }

        Row {
          spacing: 12

          Rectangle {
            width: 11
            height: 11
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: UPower.onBattery ? "#ff6b35" : "#9cf23a"
          }

          Text {
            text: root.powerState + (root.batteryPercent >= 0 ? "  ·  " + root.batteryPercent + "%" : "")
            color: "#eee8ff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
          }
        }

        Text {
          text: "INPUT DETECTED → RESUME"
          color: "#a794c7"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
          font.letterSpacing: 1
        }
      }
    }
  }
}
