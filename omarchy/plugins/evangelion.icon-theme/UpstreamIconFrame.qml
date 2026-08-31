import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

BarWidget {
  id: root

  required property string upstreamSource
  required property string upstreamModule
  property string systemLabel: "SYSTEM"

  readonly property var nativeItem: nativeLoader.item

  implicitWidth: Math.max(Style.space(28), nativeItem ? nativeItem.implicitWidth : 0)
  implicitHeight: Math.max(barSize, nativeItem ? nativeItem.implicitHeight : 0)
  function open() { if (nativeItem && typeof nativeItem.open === "function") nativeItem.open() }
  function close() { if (nativeItem && typeof nativeItem.close === "function") nativeItem.close() }
  function toggle() { if (nativeItem && typeof nativeItem.toggle === "function") nativeItem.toggle() }

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
}
