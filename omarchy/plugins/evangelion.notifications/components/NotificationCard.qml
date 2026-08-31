// Notification card. Pure presentational — no service, Notification, or
// ListModel references. The popup container drives lifetime; the history
// panel drives static rendering. Both use the same component.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "../NotificationLogic.js" as NotificationLogic

BorderSurface {
  id: root

  property string app: ""
  property string appIcon: ""
  property string summary: ""
  property string body: ""
  property string image: ""
  // Nerd Font glyph rendered in the icon slot when no real icon is set.
  // Used by omarchy-notification-send so user-action toasts (`Silenced
  // notifications` etc.) show their bell/lock/etc. glyph without leaking
  // into the summary text.
  property string glyph: ""
  // NotificationUrgency: Low=0, Normal=1, Critical=2 (upstream).
  property int urgency: 1
  property double timestamp: 0
  property int cornerRadius: 0
  property bool popupAnimated: false
  property string motionMode: "full"
  property var contextSurface: ({active:false,status:"baseline"})

  // System monospace font injected by the container.
  property string fontFamily: ""

  readonly property bool hovered: hoverTracker.hovered

  signal closeRequested()
  signal cardClicked()
  // Prefer per-notification media/avatar data, then fall back to the app icon.
  // The `check` flag avoids Qt's missing-texture placeholder for unknown names.
  readonly property string smallIconSource: image.length > 0 ? image : iconSource(appIcon)
  readonly property bool hasGlyph: glyph.length > 0
  readonly property bool compactGlyph: NotificationLogic.shouldRenderCompactGlyph(glyph, smallIconSource, singleLineToast)
  readonly property bool hasSmallIcon: smallIconSource.length > 0
  readonly property bool summaryStartsWithGlyph: NotificationLogic.summaryStartsWithGlyph(summary)
  readonly property bool singleLineToast: sanitizedBody.length === 0
  readonly property bool collapseRedundantIcon: singleLineToast && !hasGlyph && summaryStartsWithGlyph
  readonly property string sanitizedBody: sanitizeBody(body)
  readonly property string styledBody: sanitizedBody.replace(/\r\n|\r|\n/g, "<br/>")

  readonly property color dimColor: Qt.darker(Color.notifications.text, 1.35)
  readonly property color bodyColor: Qt.darker(Color.notifications.text, 1.10)
  readonly property color severityColor: urgency === 2 ? "#FF4055" : (urgency === 1 ? "#F6B73C" : "#9CF23A")
  readonly property string severityLabel: urgency === 2 ? "CRITICAL ALERT" : (urgency === 1 ? "SYSTEM WARNING" : "MAGI INFORMATION")
  readonly property string severityGlyph: urgency === 2 ? "▲" : (urgency === 1 ? "◆" : "●")
  readonly property color contextColor: ({critical:"#FF4055",constrained:"#F6D447",offline:"#F6D447",docked:"#62D8FF",mobile:"#9CF23A","media-active":"#B76CFF"})[String(contextSurface.status||"")] || severityColor
  readonly property color accentColor: urgency === 0 && contextSurface.active ? contextColor : severityColor
  readonly property var cardBorderSpec: Border.flat(accentColor, Math.max(1, Style.space(2)))

  function sanitizeBody(s) {
    return NotificationLogic.sanitizeBody(s, app, appIcon)
  }

  function iconSource(icon) {
    var value = String(icon || "")
    if (value.length === 0) return ""
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, true)
  }

  implicitWidth: Math.max(280, Math.min(Style.space(420), Screen.width - Style.space(24)))
  // Add vertical border insets so mainColumn (inset by border on top/left/right)
  // doesn't push content under the bottom edge.
  implicitHeight: mainColumn.implicitHeight + borderTop + borderBottom
  radius: cornerRadius
  color: Color.notifications.background
  borderSpec: cardBorderSpec
  clip: true

  // In-place notification replacements keep the same delegate, so repeated
  // events coalesce without replaying an entrance. Critical cards and Off
  // mode are visible immediately; Reduced uses only a short fade.
  opacity: popupAnimated && urgency !== 2 && motionMode !== "off" ? 0 : 1
  scale: popupAnimated && urgency !== 2 && motionMode === "full" ? 0.985 : 1

  Component.onCompleted: {
    if (!popupAnimated || urgency === 2 || motionMode === "off") return
    entrance.start()
  }

  ParallelAnimation {
    id: entrance
    NumberAnimation {
      target: root
      property: "opacity"
      to: 1
      duration: root.motionMode === "reduced" ? 80 : 140
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "scale"
      to: 1
      duration: root.motionMode === "full" ? 140 : 0
      easing.type: Easing.OutCubic
    }
  }

  HoverHandler { id: hoverTracker }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.closeRequested()
      } else {
        root.cardClicked()
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    // Inset by the card border so the content doesn't paint over the card's
    // outer border.
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: root.borderTop
    anchors.leftMargin: root.borderLeft
    anchors.rightMargin: root.borderRight
    spacing: 0

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(4)
      color: root.severityColor
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      Layout.topMargin: Style.space(8)
      spacing: Style.space(8)

      Text {
        text: root.severityGlyph + "  " + root.severityLabel
        color: root.severityColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        font.letterSpacing: 1
      }

      Item { Layout.fillWidth: true }

      Text {
        Layout.maximumWidth: Style.space(150)
        text: (root.app || "UNKNOWN SOURCE").toUpperCase()
        color: root.dimColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
      }
    }

    // Text content.
    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      Layout.topMargin: Style.space(8)
      Layout.bottomMargin: Style.space(8)
      spacing: root.collapseRedundantIcon ? 0 : (root.compactGlyph ? Style.space(8) : Style.space(12))

      Item {
        id: smallIconSlot
        Layout.preferredWidth: visible ? Style.space(40) : 0
        Layout.preferredHeight: visible ? Style.space(40) : 0
        Layout.alignment: Qt.AlignVCenter
        // Hide the slot when the icon failed to resolve (themed-icon name
        // not in the user's icon theme) AND we don't have a glyph fallback
        // — prevents rendering Qt's pink broken-image placeholder.
        visible: !root.collapseRedundantIcon && !root.compactGlyph && (root.hasSmallIcon || root.hasGlyph) && (root.hasGlyph || smallIconImage.status !== Image.Error)

        Image {
          id: smallIconImage
          anchors.fill: parent
          source: root.smallIconSource
          sourceSize.width: smallIconSlot.width * Screen.devicePixelRatio
          sourceSize.height: smallIconSlot.height * Screen.devicePixelRatio
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          visible: !root.hasGlyph || smallIconImage.status === Image.Ready
        }

        // Glyph fallback (Nerd Font character) when no image icon is
        // available. Used by omarchy-notification-send's `-g` flag.
        Text {
          anchors.centerIn: parent
          visible: root.hasGlyph && smallIconImage.status !== Image.Ready
          text: root.glyph
          color: Color.notifications.text
          font.family: root.fontFamily
          font.pixelSize: Style.font.displayLarge
        }
      }

      Text {
        Layout.alignment: Qt.AlignVCenter
        visible: root.compactGlyph
        text: root.glyph
        color: Color.notifications.text
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: Style.space(2)

        Text {
          Layout.fillWidth: true
          visible: root.summary.length > 0
          text: root.summary
          font.family: "Liberation Sans"
          color: Color.notifications.text
          font.pixelSize: Style.font.title
          font.bold: true
          wrapMode: Text.WordWrap
          elide: Text.ElideRight
          maximumLineCount: 2
        }

        Text {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(2)
          visible: root.sanitizedBody.length > 0
          text: root.styledBody
          textFormat: Text.StyledText
          font.family: "Liberation Sans"
          color: root.bodyColor
          font.pixelSize: Style.font.title
          wrapMode: Text.WordWrap
          elide: Text.ElideRight
          maximumLineCount: 3
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      color: root.severityColor
      opacity: 0.28
    }

    Text {
      Layout.fillWidth: true
      Layout.leftMargin: Style.space(12)
      Layout.rightMargin: Style.space(12)
      Layout.topMargin: Style.space(6)
      Layout.bottomMargin: Style.space(7)
      text: "ACTIVATE: LEFT CLICK   //   DISMISS: RIGHT CLICK"
      color: root.dimColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 0.5
      elide: Text.ElideRight
    }
  }

}
