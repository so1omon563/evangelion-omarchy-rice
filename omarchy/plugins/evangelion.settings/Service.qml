import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion
import "../evangelion.localization" as Localization

Item {
  id: root
  property bool opened: false
  property var settings: []
  property int selected: 0
  property int choice: 0
  property var pending: null
  property string notice: ""
  readonly property var targetScreen: (Quickshell.screens || []).length ? Quickshell.screens[0] : null
  readonly property var active: settings.length ? settings[Math.max(0, Math.min(selected, settings.length - 1))] : null
  function visualValue(id, fallback) { for (var i=0;i<settings.length;i++) if(settings[i].id==="visual."+id)return settings[i].value||fallback; return fallback }
  readonly property real densityScale: visualValue("density","balanced")==="compact"?.88:(visualValue("density","balanced")==="comfortable"?1.12:1)
  readonly property real fontScale: visualValue("typography","standard")==="compact"?.92:(visualValue("typography","standard")==="large"?1.14:1)
  readonly property real panelAlpha: visualValue("panel_treatment","glass")==="opaque"?1:(visualValue("panel_treatment","glass")==="minimal"?.86:.94)
  readonly property real accentAlpha: visualValue("accent_strength","balanced")==="subtle"?.55:(visualValue("accent_strength","balanced")==="vivid"?1:.78)
  readonly property int rowHeight: 44
  Motion.MotionState { id: motion }
  Localization.I18n { id: i18n }

  function refresh() { if (!statusProc.running) statusProc.running = true }
  function show() { opened = true; pending = null; notice = ""; refresh(); keyCatcher.forceActiveFocus() }
  function hide() { opened = false; pending = null }
  function revealSelection() {
    if (!settings.length) return
    var top=selected*(rowHeight+5), bottom=top+rowHeight
    if(top<listFlick.contentY)listFlick.contentY=top
    else if(bottom>listFlick.contentY+listFlick.height)listFlick.contentY=Math.min(listFlick.contentHeight-listFlick.height,bottom-listFlick.height)
  }
  function move(amount) { if (!settings.length) return; selected = (selected + amount + settings.length) % settings.length; syncChoice(); pending = null; Qt.callLater(revealSelection) }
  function syncChoice() {
    if (!active) return
    var index = active.values.indexOf(active.value)
    choice = index < 0 ? 0 : index
  }
  function cycle(amount) {
    if (!active || active.read_only || active.capability.status !== "available") return
    choice = (choice + amount + active.values.length) % active.values.length
    pending = null
  }
  function preview() {
    if (!active || active.read_only || active.capability.status !== "available") return
    previewProc.command = ["magi-settings", "preview", active.id, active.values[choice]]
    previewProc.running = true
  }
  function applyPending() {
    if (!pending || applyProc.running) return
    applyProc.command = ["magi-settings", "apply", pending.setting, pending.after, "--confirm", pending.plan_id]
    applyProc.running = true
  }
  function acceptStatus(text) {
    try { var value = JSON.parse(String(text)); settings = value.settings || []; if (selected >= settings.length) selected = 0; syncChoice() }
    catch (error) { notice = i18n.tr("settings.error") }
  }

  Process { id: statusProc; command: ["magi-settings", "status"]; stdout: StdioCollector { onStreamFinished: root.acceptStatus(text) } }
  Process { id: previewProc; stdout: StdioCollector { onStreamFinished: { try { root.pending = JSON.parse(String(text)); root.notice = "" } catch (error) { root.notice = i18n.tr("settings.error") } } } }
  Process { id: applyProc; stdout: StdioCollector { onStreamFinished: { try { JSON.parse(String(text)); root.pending = null; root.notice = i18n.tr("settings.applied"); root.refresh() } catch (error) { root.notice = i18n.tr("settings.error") } } } }
  Process { id: undoProc; command: ["magi-settings", "undo"]; stdout: StdioCollector { onStreamFinished: { root.pending = null; root.notice = i18n.tr("settings.undone"); root.refresh() } } }
  Process { id: workspaceEditor; command: ["omarchy-shell", "workspace-names", "open"] }

  IpcHandler { target: "magi-settings"
    function toggle(): string { root.opened ? root.hide() : root.show(); return root.opened ? "open" : "closed" }
    function open(): string { root.show(); return "open" }
    function close(): string { root.hide(); return "closed" }
    function refresh(): string { root.refresh(); return "ok" }
  }

  PanelWindow {
    screen: root.targetScreen; visible: root.opened; color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.namespace: "magi-settings"; WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive; exclusionMode: ExclusionMode.Ignore
    Rectangle { anchors.fill: parent; color: Qt.rgba(.027,.024,.063,.85) }
    MouseArea { anchors.fill: parent; onClicked: root.hide() }

    Rectangle {
      width: Math.min(parent.width - 80, 1080 * root.densityScale); height: Math.min(parent.height - 80, 720 * root.densityScale)
      anchors.centerIn: parent; color: Qt.rgba(.039,.031,.063,root.panelAlpha); border.width: 2; border.color: Qt.rgba(.965,.831,.278,root.accentAlpha); radius: 4
      opacity: motion.off || root.opened ? 1 : 0
      Behavior on opacity { enabled: !motion.off; NumberAnimation { duration: motion.standardMs; easing.type: Easing.OutCubic } }
      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher; anchors.fill: parent; focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) root.hide()
          else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) root.move(-1)
          else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) root.move(1)
          else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) root.cycle(-1)
          else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) root.cycle(1)
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.preview()
          else if (event.key === Qt.Key_A && root.pending) root.applyPending()
          else if (event.key === Qt.Key_U) { if (!undoProc.running) undoProc.running = true }
          else if (event.key === Qt.Key_R) root.refresh()
          else if (event.key === Qt.Key_W) { root.hide(); workspaceEditor.running = true }
          else return
          event.accepted = true
        }

        Column {
          anchors.fill: parent; anchors.margins: 26; spacing: 16
          Row {
            width: parent.width; height: 54
            Column { width: parent.width * .72; spacing: 4
              Text { text: i18n.tr("settings.title").toUpperCase(); color: "#f6d447"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.bold: true; font.letterSpacing: 2 }
              Text { text: i18n.tr("settings.subtitle").toUpperCase(); color: "#a89eb0"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.letterSpacing: 1 }
            }
            Text { width: parent.width * .28; horizontalAlignment: Text.AlignRight; text: "MAGI // 01"; color: "#62d8ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
          }
          Rectangle { width: parent.width; height: 1; color: "#6e5720" }
          Row {
            width: parent.width; height: parent.height - 150; spacing: 18
            Flickable {
              id:listFlick; width:parent.width*.53; height:parent.height; clip:true; boundsBehavior:Flickable.StopAtBounds
              contentWidth:width; contentHeight:listColumn.height
              Column { id:listColumn; width:listFlick.width; spacing:5
              Repeater {
                model: root.settings
                delegate: Rectangle {
                  required property var modelData; required property int index
                  width: parent.width; height: root.rowHeight; color: index === root.selected ? "#3af6d447" : "#8a100d16"
                  border.width: index === root.selected ? 1 : 0; border.color: "#f6d447"
                  Row { anchors.fill: parent; anchors.margins: 10; spacing: 10
                    Text { width: 26; text: String(index + 1).padStart(2, "0"); color: index === root.selected ? "#f6d447" : "#70667a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                    Column { width: parent.width - 150; spacing: 2
                      Text { width: parent.width; elide: Text.ElideRight; text: String(modelData.label).toUpperCase(); color: index === root.selected ? "#fff6dc" : "#c4bacb"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12*root.fontScale; font.bold: true }
                      Text { text: String(modelData.category).toUpperCase(); color: "#82768d"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.letterSpacing: 1 }
                    }
                    Text { width: 94; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft; text: modelData.read_only ? "LOCKED" : String(modelData.value || "—").toUpperCase(); color: modelData.capability.status === "available" ? "#62d8ff" : "#f05a68"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
                  }
                  MouseArea { anchors.fill: parent; onClicked: { root.selected = index; root.syncChoice(); root.pending = null; Qt.callLater(root.revealSelection) } }
                }
              }}
            }
            Rectangle {
              width: parent.width * .47 - 18; height: parent.height; color: "#b308070d"; border.width: 1; border.color: "#7450a6"
              Column { anchors.fill: parent; anchors.margins: 22; spacing: 14
                Text { text: root.active ? String(root.active.category).toUpperCase() + " // CONTROL" : ""; color: "#f6d447"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: root.active ? String(root.active.label).toUpperCase() : ""; color: "#fff6dc"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; font.bold: true }
                Rectangle { width: parent.width; height: 70; color: "#70181320"; border.width: 1; border.color: "#6e5720"
                  Column { anchors.fill: parent; anchors.margins: 12; spacing: 6
                    Text { text: i18n.tr("settings.target").toUpperCase(); color: "#8f8299"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                    Text { width: parent.width; elide: Text.ElideRight; text: root.active ? (root.active.read_only ? "ALWAYS-ON // SAFETY LOCK" : String(root.active.values[root.choice]).toUpperCase()) : "—"; color: "#62d8ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true }
                  }
                }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: root.active && root.active.capability.status !== "available" ? root.active.capability.reason : (root.active && root.active.read_only ? root.active.reason : i18n.tr("settings.preview_hint")); color: root.active && (root.active.read_only || root.active.capability.status !== "available") ? "#f05a68" : "#a89eb0"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                Rectangle { width: parent.width; height: 1; color: "#46354f" }
                Text { text: i18n.tr("settings.preview").toUpperCase(); color: "#f6d447"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: root.pending ? String(root.pending.before).toUpperCase() + "  →  " + String(root.pending.after).toUpperCase() : i18n.tr("settings.no_preview"); color: root.pending ? "#fff6dc" : "#70667a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: root.pending !== null }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: root.pending ? root.pending.effects.join("\n") : ""; color: "#a89eb0"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                Item { width: 1; height: 1 }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: root.notice; color: "#62d8ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
              }
            }
          }
          Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: i18n.tr("settings.keys").toUpperCase()+"  ·  W "+i18n.tr("settings.workspaces").toUpperCase(); color: "#8f8299"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.letterSpacing: .5 }
        }
      }
    }
  }
}
