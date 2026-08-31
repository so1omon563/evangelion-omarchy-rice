import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string mode: "full"
  readonly property bool full: mode === "full"
  readonly property bool reduced: mode === "reduced"
  readonly property bool off: mode === "off"
  readonly property int standardMs: full ? 140 : (reduced ? 80 : 0)
  readonly property int criticalMs: 0

  function refresh() {
    if (!probe.running) probe.running = true
  }

  Component.onCompleted: refresh()

  property FileView stateView: FileView {
    path: Quickshell.env("HOME") + "/.local/state/evangelion-rice/motion/state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  property Process probe: Process {
    command: ["magi-motion", "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var value = JSON.parse(text)
          root.mode = value.mode === "reduced" || value.mode === "off" ? value.mode : "full"
        } catch (error) {
          root.mode = "full"
        }
      }
    }
  }
}
