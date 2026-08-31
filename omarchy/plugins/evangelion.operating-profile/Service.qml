import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var shell: null
  property int screenCount: Quickshell.screens.length

  onScreenCountChanged: settle.restart()
  Component.onCompleted: settle.start()

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/evangelion-rice/context/state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: automationSettle.restart()
  }

  Timer {
    id: automationSettle
    interval: 350
    repeat: false
    onTriggered: if (!automationApply.running) automationApply.running = true
  }

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
    command: ["magi-context", "refresh"]
  }

  Process {
    id: automationApply
    command: ["magi-context-automation", "apply"]
  }

  IpcHandler {
    target: "operating-profile"
    function apply(): string { settle.restart(); return "context refresh queued" }
    function automate(): string { automationSettle.restart(); return "queued" }
  }
}
