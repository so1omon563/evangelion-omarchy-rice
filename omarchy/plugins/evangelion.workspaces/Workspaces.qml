import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  readonly property var magiLabels: ({
    1: "01·MEL",
    2: "02·BAL",
    3: "03·CAS",
    4: "04·ENT",
    5: "05·TRM"
  })

  readonly property var magiNames: ({
    1: "MAGI-01 · MELCHIOR",
    2: "MAGI-02 · BALTHASAR",
    3: "MAGI-03 · CASPER",
    4: "WORKSPACE-04 · ENTRY",
    5: "WORKSPACE-05 · TERMINAL"
  })

  readonly property var magiAccents: ({
    1: "#9CF23A", // MELCHIOR — MAGI green
    2: "#F6B73C", // BALTHASAR — warning amber
    3: "#B76CFF", // CASPER — EVA violet
    4: "#FF4055", // ENTRY — synchronization red
    5: "#42C8FF"  // TERMINAL — telemetry cyan
  })

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++)
      if (values[i].id === id) return values[i]
    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function labelFor(id, focused) {
    if (root.vertical) return id === 10 ? "0" : String(id)
    var label = root.magiLabels[id] || String(id).padStart(2, "0")
    return label
  }

  function widthFor(id) {
    if (root.vertical) return root.barSize
    if (id >= 1 && id <= 5) return 70
    return 34
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \\\"" + id + "\\\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)
  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : 1
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()
      WidgetButton {
        required property int modelData
        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property color workspaceAccent: root.magiAccents[modelData] || (root.bar ? root.bar.urgent : Color.urgent)
        bar: root.bar
        text: root.labelFor(modelData, focused)
        tooltipText: root.magiNames[modelData] || "WORKSPACE-" + String(modelData).padStart(2, "0")
        active: focused
        activeColor: workspaceAccent
        opacity: occupied || focused ? 1 : 0.42
        horizontalMargin: 5
        verticalPadding: 6
        fixedWidth: root.widthFor(modelData)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

      }
    }
  }
}
