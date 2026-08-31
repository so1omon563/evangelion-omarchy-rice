import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland

Item {
  id: root

  property var shell: null
  property bool initialized: false
  property bool opened: false
  property bool reducedMotion: false
  property bool lastOnBattery: false
  property bool pendingOnBattery: false
  property double lastShownAt: 0
  property int transitionCount: 0
  property string heading: "UMBILICAL POWER CONNECTED"
  property string detail: "EXTERNAL SUPPLY // SYNCHRONIZED"
  property string metric: ""
  property color accent: "#9cf23a"
  readonly property int flapCooldownMs: 10000

  function percentage() {
    var device = UPower.displayDevice
    if (!device || !device.isPresent) return -1
    return Math.round(Number(device.percentage || 0) * 100)
  }

  function durationText(seconds) {
    var total = Math.round(Number(seconds || 0))
    if (total < 60 || total > 7 * 24 * 60 * 60) return ""
    var hours = Math.floor(total / 3600)
    var minutes = Math.floor((total % 3600) / 60)
    if (hours > 0) return hours + "H " + String(minutes).padStart(2, "0") + "M"
    return minutes + " MIN"
  }

  function metricFor(onBattery) {
    var device = UPower.displayDevice
    var percent = percentage()
    var parts = []
    if (percent >= 0) parts.push(percent + "%")
    if (device) {
      var duration = durationText(onBattery ? device.timeToEmpty : device.timeToFull)
      if (duration !== "") parts.push((onBattery ? "EST. RUNTIME " : "CHARGE COMPLETE ") + duration)
      else if (!onBattery && device.state === UPowerDeviceState.FullyCharged) parts.push("CHARGE COMPLETE")
    }
    return parts.join("  ·  ")
  }

  function populate(onBattery) {
    heading = onBattery ? "INTERNAL POWER" : "UMBILICAL POWER CONNECTED"
    detail = onBattery ? "BATTERY RESERVE // ACTIVE" : "EXTERNAL SUPPLY // SYNCHRONIZED"
    metric = metricFor(onBattery)
    accent = onBattery ? "#f6a52f" : "#9cf23a"
  }

  function show(onBattery, genuine) {
    populate(onBattery)
    opened = true
    if (genuine) {
      lastShownAt = Date.now()
      transitionCount++
      if (!soundProcess.running) {
        soundProcess.command = ["magi-sound", "power"]
        soundProcess.running = true
      }
    }
    retireTimer.restart()
  }

  function observePower() {
    var current = UPower.onBattery
    if (!initialized) {
      lastOnBattery = current
      pendingOnBattery = current
      initialized = true
      return
    }
    pendingOnBattery = current
    settleTimer.restart()
  }

  function commitTransition() {
    var current = pendingOnBattery
    if (current === lastOnBattery) return
    var remaining = flapCooldownMs - (Date.now() - lastShownAt)
    if (remaining > 0) {
      cooldownTimer.interval = Math.max(250, remaining)
      cooldownTimer.restart()
      return
    }
    lastOnBattery = current
    show(current, true)
  }

  function refreshPreferences() {
    if (!preferenceProbe.running) preferenceProbe.running = true
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() { root.observePower() }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/evangelion-screensaver.json"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshPreferences()
  }

  Process {
    id: preferenceProbe
    running: true
    command: ["bash", "-c", "if jq -e '.reduced_motion == true' $HOME/.config/omarchy/evangelion-screensaver.json >/dev/null 2>&1; then echo yes; else echo no; fi"]
    stdout: SplitParser { onRead: function(line) { root.reducedMotion = String(line).trim() === "yes" } }
  }

  Process { id: soundProcess }

  Timer { id: settleTimer; interval: 1200; repeat: false; onTriggered: root.commitTransition() }
  Timer { id: cooldownTimer; interval: root.flapCooldownMs; repeat: false; onTriggered: root.commitTransition() }
  Timer { id: retireTimer; interval: root.reducedMotion ? 1800 : 2800; repeat: false; onTriggered: root.opened = false }

  IpcHandler {
    target: "power-sequence"
    function preview(source: string): string {
      var battery = source === "battery" || source === "internal"
      root.show(battery, false)
      return root.heading
    }
    function hide(): string { root.opened = false; retireTimer.stop(); return "hidden" }
    function reload(): string { root.refreshPreferences(); return "reloading" }
    function state(): string {
      return JSON.stringify({
        initialized: root.initialized,
        visible: root.opened,
        source: root.lastOnBattery ? "battery" : "ac",
        pendingSource: root.pendingOnBattery ? "battery" : "ac",
        reducedMotion: root.reducedMotion,
        transitionCount: root.transitionCount,
        cooldownMs: root.flapCooldownMs,
        settleMs: settleTimer.interval,
        heading: root.heading,
        metric: root.metric
      })
    }
  }

  Component.onCompleted: Qt.callLater(root.observePower)

  PanelWindow {
    visible: root.opened
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "magi-power-sequence"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      id: card
      width: Math.min(520, parent.width * 0.45)
      height: root.metric === "" ? 132 : 154
      anchors.left: parent.left
      anchors.leftMargin: Math.max(34, parent.width * 0.055)
      anchors.verticalCenter: parent.verticalCenter
      radius: 3
      color: "#ed080710"
      border.width: 2
      border.color: root.accent
      opacity: root.opened ? 1 : 0

      Behavior on opacity { enabled: !root.reducedMotion; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

      Rectangle {
        width: 8
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        color: root.accent
      }
      Rectangle {
        width: 72
        height: 3
        anchors { top: parent.top; right: parent.right }
        anchors.topMargin: 14
        anchors.rightMargin: 16
        color: "#7b2cbf"
      }

      Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 32; rightMargin: 24 }
        spacing: 9
        Text { width: parent.width; text: root.heading; color: root.accent; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; font.bold: true; font.letterSpacing: 1.1 }
        Rectangle { width: parent.width; height: 1; color: "#7450a6" }
        Text { width: parent.width; text: root.detail; color: "#eee8ff"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 0.7 }
        Text { visible: root.metric !== ""; text: root.metric; color: "#a794c7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
      }
    }
  }
}
