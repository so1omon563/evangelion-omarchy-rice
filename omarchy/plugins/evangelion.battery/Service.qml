import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "BatteryModel.js" as BatteryModel

Item {
  id: root

  property var shell: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property int warningThreshold: 15
  readonly property int criticalThreshold: 7
  property string pendingPowerSource: ""

  PersistentProperties {
    id: persisted
    reloadableId: "omarchy-battery"
    property bool warnedReserve: false
    property bool warnedCritical: false
  }

  function batteryPercentage() {
    return BatteryModel.batteryPercentage(UPower.displayDevice)
  }

  function isDischarging() {
    return BatteryModel.isDischarging(UPower.displayDevice, UPower.onBattery, UPowerDeviceState.Discharging)
  }

  function checkBattery() {
    var level = batteryPercentage()
    if (!isDischarging() || level < 0) {
      persisted.warnedReserve = false
      persisted.warnedCritical = false
      return
    }

    if (level > warningThreshold) {
      persisted.warnedReserve = false
      persisted.warnedCritical = false
      return
    }

    if (level <= criticalThreshold) {
      if (!persisted.warnedCritical) sendBatteryWarning("critical", level)
      persisted.warnedReserve = true
      persisted.warnedCritical = true
      return
    }

    if (!persisted.warnedReserve) sendBatteryWarning("reserve", level)
    persisted.warnedReserve = true
    persisted.warnedCritical = false
  }

  function sendBatteryWarning(tier, level) {
    if (warningProcess.running) return
    warningProcess.command = [
      "magi-battery-alert",
      tier,
      String(level)
    ]
    warningProcess.running = true
  }

  function applyPowerProfile() {
    pendingPowerSource = UPower.onBattery ? "battery" : "ac"
    if (!powerProfileProcess.running) runPendingPowerProfile()
  }

  function runPendingPowerProfile() {
    powerProfileProcess.command = ["omarchy-powerprofiles-set", pendingPowerSource]
    pendingPowerSource = ""
    powerProfileProcess.running = true
  }

  Process { id: warningProcess }

  Process {
    id: powerProfileProcess
    onExited: if (root.pendingPowerSource !== "") root.runPendingPowerProfile()
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkBattery()
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() {
      root.checkBattery()
      root.applyPowerProfile()
    }
  }
}
