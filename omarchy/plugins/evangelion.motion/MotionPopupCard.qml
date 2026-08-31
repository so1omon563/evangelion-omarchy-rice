import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

PopupWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property var owner: null
  property int margin: Style.gapsOut
  property int padding: Style.spacing.popupPadding
  property int contentWidth: Style.space(280)
  property int contentHeight: Style.space(200)
  property color borderColor: Color.popups.border
  property var borderSpec: Border.localOrSurfaceSpec("popups", "border", borderColor, Color.popups.border, Math.max(1, Style.space(2)))
  property bool open: false
  property bool centerOnBar: false
  property string triggerMode: "click"

  MotionState { id: motion }

  readonly property var coordinatorKey: owner || root
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property var popupScreen: anchorWindow ? anchorWindow.screen : null
  readonly property bool containsMouse: cardHover.hovered
  readonly property real screenW: popupScreen ? popupScreen.width : 0
  readonly property real screenH: popupScreen ? popupScreen.height : 0
  readonly property real barW: anchorWindow ? anchorWindow.width : 0
  readonly property real barH: anchorWindow ? anchorWindow.height : 0
  readonly property real availableCardWidth: screenW > 0
    ? Math.max(120, screenW - ((bar && (bar.position === "left" || bar.position === "right")) ? barW : 0) - root.margin * 2) : 0
  readonly property real availableCardHeight: screenH > 0
    ? Math.max(120, screenH - ((bar && (bar.position === "top" || bar.position === "bottom")) ? barH : 0) - root.margin * 2) : 0
  readonly property real verticalContentInset: padding * 2 + Border.top(borderSpec) + Border.bottom(borderSpec)

  function fittedContentWidth(width, cap) {
    var desired = Math.max(1, Number(width) || 1)
    var maximum = root.availableCardWidth > 0 ? root.availableCardWidth : desired
    if (cap !== undefined && Number(cap) > 0) maximum = Math.min(maximum, Number(cap))
    return Math.round(Math.min(desired, maximum))
  }

  function fittedContentHeight(height, cap) {
    var desired = Math.max(root.verticalContentInset, (Number(height) || 0) + root.verticalContentInset)
    var maximum = root.availableCardHeight > 0 ? root.availableCardHeight : desired
    if (cap !== undefined && Number(cap) > 0) maximum = Math.min(maximum, Number(cap))
    return Math.round(Math.min(desired, maximum))
  }

  function cappedContentHeight(height) {
    return Math.round(Math.min(Math.max(root.padding * 2, Number(height) || root.padding * 2),
      root.availableCardHeight > 0 ? root.availableCardHeight : Number(height)))
  }

  function close() {
    if (owner && "close" in owner) owner.close()
    else root.open = false
  }

  default property alias contentItem: contentHolder.children

  visible: open || card.opacity > 0
  color: "transparent"
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  onOpenChanged: {
    if (bar) {
      if (open) bar.requestPopout(coordinatorKey)
      else if (bar.activePopout === coordinatorKey) bar.releasePopout(coordinatorKey)
    }
    if (open && motion.full) acquisition.restart()
    else acquisition.stop()
  }

  HyprlandFocusGrab {
    active: root.open && root.triggerMode === "click"
    windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
    onCleared: root.close()
  }

  anchor {
    id: popupAnchor
    window: anchorItem ? anchorItem.QsWindow.window : null
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1
    onAnchoring: {
      if (!root.anchorItem || !root.bar) return
      var target = root.anchorItem
      var localX = target.width / 2 - root.implicitWidth / 2
      var localY = target.height + root.margin
      if (root.bar.position === "bottom") localY = -root.implicitHeight - root.margin
      else if (root.bar.position === "left") { localX = target.width + root.margin; localY = target.height / 2 - root.implicitHeight / 2 }
      else if (root.bar.position === "right") { localX = -root.implicitWidth - root.margin; localY = target.height / 2 - root.implicitHeight / 2 }
      var window = target.QsWindow.window
      if (!window) return
      if (root.centerOnBar) {
        var cx = 0, cy = 0
        if (root.bar.position === "top" || root.bar.position === "bottom") {
          cx = Math.max(root.margin, Math.min(window.width / 2 - root.implicitWidth / 2, window.width - root.implicitWidth - root.margin))
          cy = root.bar.position === "bottom" ? -root.implicitHeight - root.margin : window.height + root.margin
        } else {
          cx = root.bar.position === "left" ? window.width + root.margin : -root.implicitWidth - root.margin
          cy = Math.max(root.margin, Math.min(window.height / 2 - root.implicitHeight / 2, window.height - root.implicitHeight - root.margin))
        }
        popupAnchor.rect.x = Math.round(cx); popupAnchor.rect.y = Math.round(cy); return
      }
      var point = window.contentItem.mapFromItem(target, localX, localY)
      if (root.bar.position === "top" || root.bar.position === "bottom") point.x = Math.max(root.margin, Math.min(point.x, window.width - root.implicitWidth - root.margin))
      else point.y = Math.max(root.margin, Math.min(point.y, window.height - root.implicitHeight - root.margin))
      popupAnchor.rect.x = Math.round(point.x); popupAnchor.rect.y = Math.round(point.y)
    }
  }

  BorderSurface {
    id: card
    anchors.fill: parent
    color: Color.popups.background
    borderSpec: root.borderSpec
    padding: root.padding
    radius: Style.cornerRadius
    opacity: root.open ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: motion.off ? 140 : motion.standardMs; easing.type: Easing.OutCubic }
    }

    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }

    Rectangle {
      id: acquisitionRail
      z: 10
      color: Color.accent
      opacity: 0
      width: root.bar && (root.bar.position === "left" || root.bar.position === "right") ? 2 : parent.width
      height: root.bar && (root.bar.position === "left" || root.bar.position === "right") ? parent.height : 2
      anchors.left: root.bar && root.bar.position === "right" ? undefined : parent.left
      anchors.right: root.bar && root.bar.position === "right" ? parent.right : undefined
      anchors.top: root.bar && root.bar.position === "bottom" ? undefined : parent.top
      anchors.bottom: root.bar && root.bar.position === "bottom" ? parent.bottom : undefined
    }

    SequentialAnimation {
      id: acquisition
      NumberAnimation { target: acquisitionRail; property: "opacity"; from: 0; to: 0.85; duration: 70 }
      NumberAnimation { target: acquisitionRail; property: "opacity"; from: 0.85; to: 0; duration: 110 }
    }

    HoverHandler { id: cardHover }
  }
}
