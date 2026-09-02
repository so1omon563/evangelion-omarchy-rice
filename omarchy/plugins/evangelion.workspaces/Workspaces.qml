import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "../evangelion.motion" as Motion

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  property var workspaceModel: []
  property real displayWidth: 1920
  readonly property bool compactBar: !root.vertical && root.displayWidth < 2000
  readonly property bool minimalBar: !root.vertical && root.displayWidth < 1200

  function identity(id) {
    for (var i = 0; i < root.workspaceModel.length; i++) if (root.workspaceModel[i].id === id) return root.workspaceModel[i]
    return ({id:id, name:"WORKSPACE-"+String(id).padStart(2,"0"), label:String(id), accent:root.bar ? root.bar.urgent : Color.urgent})
  }
  function refreshNames() {
    if (nameProbe.running) { nameRefresh.restart(); return }
    var screen=root.QsWindow.window&&root.QsWindow.window.screen?root.QsWindow.window.screen.name:""
    nameProbe.command=["magi-workspaces","status","--json","--width",String(root.displayWidth),"--screen",screen]
    nameProbe.running=true
  }
  function loadNames(text) {
    try {
      var rows=JSON.parse(String(text)).workspaces||[],used=({}),resolved=[]
      for(var i=0;i<rows.length;i++){
        var row=rows[i],base=String(row.short||"AUX").toUpperCase().slice(0,6),candidate=base,index=1
        while(used[candidate]){index++;var suffix=String(index);candidate=base.slice(0,Math.max(1,6-suffix.length))+suffix}
        used[candidate]=true;var copy=Object.assign({},row);copy.resolved_short=candidate;resolved.push(copy)
      }
      root.workspaceModel=resolved
    } catch(error) {}
  }
  Component.onCompleted: Qt.callLater(root.refreshNames)
  FileView { path: Quickshell.env("HOME")+"/.config/omarchy/workspaces.json"; watchChanges:true; printErrors:false; onLoaded:root.loadNames(text()); onFileChanged:root.loadNames(text()) }
  Timer { id:nameRefresh; interval:80; repeat:false; onTriggered:root.refreshNames() }
  Process { id:nameProbe; stdout:StdioCollector { onStreamFinished:{ try { var value=JSON.parse(String(text));root.displayWidth=value.width||1920;root.workspaceModel=value.workspaces||[] } catch(error){} } } }

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
    if (root.minimalBar) return id === 10 ? "0" : String(id)
    var item=root.identity(id)
    if(root.compactBar)return String(id).padStart(2,"0")+"·"+(item.resolved_short||String(id))
    return String(id).padStart(2,"0")+"·"+String(item.name||id).split("·").pop().trim().slice(0,12)
  }

  function widthFor(id) {
    if (root.vertical) return root.barSize
    if (root.minimalBar) return 30
    if (id >= 1 && id <= 5) return root.compactBar ? 48 : Math.min(130, Math.max(70, 26 + root.identity(id).label.length * 7))
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
        readonly property var identity: root.identity(modelData)
        readonly property color workspaceAccent: identity.accent || (root.bar ? root.bar.urgent : Color.urgent)
        bar: root.bar
        text: root.labelFor(modelData, focused)
        tooltipText: identity.name || "WORKSPACE-" + String(modelData).padStart(2, "0")
        active: focused
        activeColor: workspaceAccent
        opacity: occupied || focused ? 1 : 0.42
        horizontalMargin: 5
        verticalPadding: 6
        fixedWidth: root.widthFor(modelData)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

        Motion.StateCue {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          active: focused
          cueColor: workspaceAccent
        }

      }
    }
  }

  // The fixed edge cue also reflects affinity palette changes without adding
  // a widget, label, or a single pixel of responsive bar width.
  Motion.StateCue {
    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
    active: true
    cueColor: Color.accent
    cueWidth: 2
  }
}
