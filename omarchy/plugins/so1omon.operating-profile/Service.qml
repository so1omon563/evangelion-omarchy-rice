import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var shell: null
  property int screenCount: Quickshell.screens.length

  onScreenCountChanged: settle.restart()
  Component.onCompleted: settle.start()

  Timer {
    id: settle
    interval: 1400
    repeat: false
    onTriggered: {
      if (!apply.running) apply.running = true
    }
  }

  Process {
    id: apply
    command: ["magi-operating-profile", "apply"]
  }

  IpcHandler {
    target: "operating-profile"
    function apply(): string { settle.restart(); return "queued" }
  }
}
