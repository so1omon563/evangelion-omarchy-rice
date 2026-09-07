import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion

Item {
  id: root
  property bool opened: false
  property var results: []
  property int selected: 0
  property var pending: null
  property string notice: ""
  readonly property var active: results.length ? results[Math.max(0, Math.min(selected, results.length - 1))] : null
  readonly property var targetScreen: (Quickshell.screens || []).length ? Quickshell.screens[0] : null
  Motion.MotionState { id: motion }

  function show() { opened = true; selected = 0; pending = null; notice = ""; query.text = ""; refresh(); query.forceActiveFocus() }
  function hide() { opened = false; pending = null; notice = "" }
  function refresh() { if (!searchProc.running) { searchProc.command = ["magi-command-palette", "search", query.text, "--json"]; searchProc.running = true } }
  function acceptResults(raw) { try { var value = JSON.parse(String(raw)); results = value.results || []; selected = Math.min(selected, Math.max(0, results.length - 1)) } catch (error) { results = []; notice = "COMMAND REGISTRY UNAVAILABLE" } }
  function move(amount) { if (!results.length) return; selected = (selected + amount + results.length) % results.length; pending = null; notice = ""; reveal() }
  function reveal() { var top = selected * 57, bottom = top + 52; if (top < list.contentY) list.contentY = top; else if (bottom > list.contentY + list.height) list.contentY = Math.max(0, bottom - list.height) }
  function activate() {
    if (!active) return
    if (pending && pending.id === active.id) { executeProc.command = ["magi-command-palette", "execute", active.id, "--confirm", pending.token]; executeProc.running = true; return }
    prepareProc.command = ["magi-command-palette", "prepare", active.id]; prepareProc.running = true
  }
  function acceptPrepare(raw) {
    try {
      var value = JSON.parse(String(raw))
      if (value.requires_confirmation) { pending = value; notice = "CONFIRM " + value.danger.toUpperCase() + " ACTION // ENTER AGAIN WITHIN 60 SECONDS" }
      else { executeProc.command = ["magi-command-palette", "execute", value.id]; executeProc.running = true }
    } catch (error) { notice = "COMMAND PREPARATION FAILED" }
  }

  Timer { id: debounce; interval: 90; onTriggered: root.refresh() }
  Process { id: searchProc; stdout: StdioCollector { onStreamFinished: root.acceptResults(text) } }
  Process { id: prepareProc; stdout: StdioCollector { onStreamFinished: root.acceptPrepare(text) } }
  Process { id: executeProc; stdout: StdioCollector { onStreamFinished: { try { JSON.parse(String(text)); root.hide() } catch (error) { root.notice = "COMMAND LAUNCH FAILED" } } } }
  IpcHandler { target: "magi-command-palette"
    function toggle(): string { root.opened ? root.hide() : root.show(); return root.opened ? "open" : "closed" }
    function open(): string { root.show(); return "open" }
    function close(): string { root.hide(); return "closed" }
  }

  PanelWindow {
    screen: root.targetScreen; visible: root.opened; color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.namespace: "magi-command-palette"; WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive; exclusionMode: ExclusionMode.Ignore
    Rectangle { anchors.fill: parent; color: "#dc030207" }
    MouseArea { anchors.fill: parent; onClicked: root.hide() }
    Rectangle {
      width: Math.min(parent.width - 48, 780); height: Math.min(parent.height - 80, 650); anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: Math.max(40, parent.height * .11)
      color: "#f4080710"; border.width: 2; border.color: "#9cf23a"; radius: 4
      opacity: motion.off || root.opened ? 1 : 0; Behavior on opacity { enabled: !motion.off; NumberAnimation { duration: motion.standardMs; easing.type: Easing.OutCubic } }
      MouseArea { anchors.fill: parent; onClicked: query.forceActiveFocus() }
      Column {
        anchors.fill: parent; anchors.margins: 22; spacing: 12
        Row { width: parent.width; height: 38
          Column { width: parent.width * .72; Text { text: "MAGI // GLOBAL COMMAND PALETTE"; color: "#9cf23a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 2 } Text { text: "STABLE REGISTRY · USAGE-INDEPENDENT ORDER"; color: "#8f8299"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 } }
          Text { width: parent.width * .28; horizontalAlignment: Text.AlignRight; text: String(root.results.length).padStart(2,"0") + " MATCHES"; color: "#62d8ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
        }
        Rectangle { width: parent.width; height: 48; color: "#b30b0911"; border.width: 1; border.color: query.activeFocus ? "#f6d447" : "#7450a6"
          TextInput { id: query; anchors.fill: parent; anchors.margins: 13; color: "#fff6dc"; selectionColor: "#7450a6"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; clip: true; Accessible.role: Accessible.EditableText; Accessible.name: "Search MAGI commands"; Accessible.description: "Type to fuzzy search, arrows navigate, Enter executes or confirms, Escape closes"; onTextChanged: { root.selected = 0; root.pending = null; root.notice = ""; debounce.restart() }
            Keys.priority: Keys.BeforeItem; Keys.onPressed: function(event) { if (event.key === Qt.Key_Escape) root.hide(); else if (event.key === Qt.Key_Down) root.move(1); else if (event.key === Qt.Key_Up) root.move(-1); else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activate(); else return; event.accepted = true }
          }
        }
        Flickable { id: list; width: parent.width; height: parent.height - 160; clip: true; contentWidth: width; contentHeight: rows.height; boundsBehavior: Flickable.StopAtBounds
          Column { id: rows; width: list.width; spacing: 5
            Repeater { model: root.results; delegate: Rectangle { required property var modelData; required property int index; width: rows.width; height: 52; color: index === root.selected ? "#309cf23a" : "#8a100d16"; border.width: index === root.selected ? 1 : 0; border.color: "#9cf23a"
              Row { anchors.fill: parent; anchors.margins: 9; spacing: 10
                Text { width: 30; text: String(index + 1).padStart(2,"0"); color: index === root.selected ? "#9cf23a" : "#736a79"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                Column { width: parent.width - 190; spacing: 2; Text { width: parent.width; elide: Text.ElideRight; text: String(modelData.label).toUpperCase(); color: "#eee8f2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true } Text { width: parent.width; elide: Text.ElideRight; text: String(modelData.description).toUpperCase(); color: "#8f8299"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 } }
                Column { width: 140; spacing: 3; Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: String(modelData.category).toUpperCase(); color: "#62d8ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.bold: true } Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: String(modelData.danger).toUpperCase(); color: modelData.danger === "destructive" ? "#ff4055" : modelData.danger === "confirm" || modelData.danger === "caution" ? "#f6a52f" : "#8f8299"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.bold: true } }
              }
              MouseArea { anchors.fill: parent; onClicked: { root.selected = index; root.pending = null; root.activate() } }
            }}
          }
        }
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.notice || "TYPE TO SEARCH · ↑↓ NAVIGATE · ENTER LAUNCH · ESC CLOSE"; color: root.pending ? "#f6a52f" : "#8f8299"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: root.pending !== null }
      }
    }
  }
}
