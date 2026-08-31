import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property string mode: "full"
  property int generation: 0
  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/evangelion.json"
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/evangelion-rice/motion/state.json"

  function refresh() {
    if (!probe.running) probe.running = true
  }

  Component.onCompleted: refresh()

  FileView {
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Process {
    id: probe
    command: ["magi-motion", "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const value = JSON.parse(text)
          root.mode = value.mode || "full"
        } catch (error) {
          root.mode = "full"
        }
        root.generation += 1
      }
    }
  }

  IpcHandler {
    target: "magi-motion"
    function status(): string { return root.mode }
    function refresh(): string { root.refresh(); return "queued" }
    function state(): string {
      return JSON.stringify({mode: root.mode, generation: root.generation})
    }
  }
}
