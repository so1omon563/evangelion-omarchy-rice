import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

BarWidget {
  id: root

  required property string upstreamSource
  required property string upstreamModule
  property string systemLabel: "SYSTEM"
  property color normalColor: Color.accent
  property color attentionColor: "#F6D447"
  property color errorColor: bar ? bar.urgent : Color.urgent
  property bool attention: false
  property bool error: false
  property real openPanelIndicatorWidth: Style.space(16)

  readonly property var nativeItem: nativeLoader.item
  readonly property bool opened: nativeItem && nativeItem.opened === true
  readonly property color stateColor: error ? errorColor : (attention ? attentionColor : (opened || hover.hovered ? normalColor : Qt.darker(normalColor, 1.35)))

  implicitWidth: Math.max(Style.space(28), nativeItem ? nativeItem.implicitWidth : 0)
  implicitHeight: Math.max(barSize, nativeItem ? nativeItem.implicitHeight : 0)
  function open() { if (nativeItem && typeof nativeItem.open === "function") nativeItem.open() }
  function close() { if (nativeItem && typeof nativeItem.close === "function") nativeItem.close() }
  function toggle() { if (nativeItem && typeof nativeItem.toggle === "function") nativeItem.toggle() }
  function alpha(colorValue, opacityValue) { return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacityValue) }

  function injectNative() {
    if (!nativeItem) return
    if ("bar" in nativeItem) nativeItem.bar = root.bar
    if ("moduleName" in nativeItem) nativeItem.moduleName = root.upstreamModule
    if ("settings" in nativeItem) nativeItem.settings = root.settings
  }

  Loader {
    id: nativeLoader
    anchors.centerIn: parent
    source: "file://" + Quickshell.env("OMARCHY_PATH") + root.upstreamSource
    onLoaded: {
      root.injectNative()
      Qt.callLater(root.injectNative)
    }
  }

  onBarChanged: injectNative()
  onSettingsChanged: injectNative()

  Rectangle {
    anchors.fill: parent
    anchors.margins: Style.space(2)
    color: root.opened ? root.alpha(root.stateColor, 0.10) : "transparent"
    border.color: root.alpha(root.stateColor, root.opened || hover.hovered ? 0.72 : 0.30)
    border.width: 1
    radius: Style.space(2)
    z: 20

    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on color { ColorAnimation { duration: 120 } }
  }

  Rectangle {
    width: Style.space(5)
    height: 1
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: Style.space(1)
    anchors.topMargin: Style.space(1)
    color: root.stateColor
    z: 21
  }

  Rectangle {
    width: Style.space(5)
    height: 1
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: Style.space(1)
    anchors.bottomMargin: Style.space(1)
    color: root.stateColor
    z: 21
  }

  HoverHandler { id: hover }
}
