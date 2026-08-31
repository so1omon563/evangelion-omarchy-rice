import QtQuick
import Quickshell
import qs.Ui
import qs.Commons
import "../evangelion.motion" as Motion

BarWidget {
  id: root
  moduleName: "evangelion.media"

  readonly property var media: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var player: media ? media.activePlayer : null
  readonly property var sources: media ? media.sourcePlayers : []
  readonly property bool hasMedia: player !== null && (player.trackTitle || player.trackArtist)
  readonly property string title: player ? (player.trackTitle || "UNKNOWN TRACK") : ""
  readonly property string artist: player ? (player.trackArtist || "") : ""
  readonly property string glyph: player && player.isPlaying ? "󰎆" : "󰏤"
  property bool popupOpen: false

  function close() { popupOpen = false }

  visible: hasMedia
  implicitWidth: hasMedia ? row.implicitWidth + Style.space(12) : 0
  implicitHeight: barSize

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(5)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.glyph
      color: root.player && root.player.isPlaying ? Color.accent : root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      width: Math.min(132, implicitWidth)
      anchors.verticalCenter: parent.verticalCenter
      text: "AUDIO // " + root.title
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      elide: Text.ElideRight
      maximumLineCount: 1
      visible: !root.bar.vertical
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (!root.media) return
      if (mouse.button === Qt.LeftButton) root.popupOpen = !root.popupOpen
      else if (mouse.button === Qt.MiddleButton) root.media.runAction("playPause", true)
      else root.media.runAction("next", true)
    }
    onWheel: function(wheel) {
      if (!root.media) return
      root.media.runAction(wheel.angleDelta.y > 0 ? "previous" : "next", true)
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.title + (root.artist ? " — " + root.artist : ""))
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  Motion.MotionPopupCard {
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(330))
    contentHeight: fittedContentHeight(panel.implicitHeight)

    Column {
      id: panel
      anchors.fill: parent
      spacing: Style.space(9)

      Text {
        text: "MAGI // AUDIO CHANNEL"
        color: Color.accent
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1
      }

      Row {
        width: parent.width
        spacing: Style.space(10)

        BorderSurface {
          width: Style.space(66)
          height: Style.space(66)
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Image {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: source !== ""
          }
          Text {
            anchors.centerIn: parent
            visible: !root.player || !root.player.trackArtUrl
            text: "󰝚"
            color: Color.accent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          width: parent.width - Style.space(76)
          spacing: Style.space(3)
          Text {
            width: parent.width
            text: root.title
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: root.artist || (root.player ? root.player.identity : "")
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: root.player && root.player.isPlaying ? "CHANNEL ACTIVE" : "CHANNEL PAUSED"
            color: root.player && root.player.isPlaying ? Color.accent : Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)
        Button { iconText: "󰒮"; foreground: root.bar.foreground; onClicked: root.media.runAction("previous", true) }
        Button { iconText: root.player && root.player.isPlaying ? "󰏤" : "󰐊"; foreground: root.bar.foreground; onClicked: root.media.runAction("playPause", true) }
        Button { iconText: "󰒭"; foreground: root.bar.foreground; onClicked: root.media.runAction("next", true) }
      }

      PanelSeparator { visible: root.sources.length > 1; foreground: root.bar.foreground }

      Repeater {
        model: root.sources
        BorderSurface {
          required property var modelData
          readonly property bool selected: root.player && root.media.playerKey(root.player) === root.media.playerKey(modelData)
          width: panel.width
          height: sourceText.implicitHeight + Style.space(10)
          color: selected ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
          borderSpec: selected ? Border.controlSpec("normal", root.bar.foreground, Color.accent) : Border.none()
          Text {
            id: sourceText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Style.space(7)
            text: (modelData.isPlaying ? "󰏤  " : "󰐊  ") + (modelData.trackTitle || modelData.identity || "Media source")
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: parent.selected
            elide: Text.ElideRight
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.media.selectPlayer(root.media.playerKey(modelData))
          }
        }
      }
    }
  }
}
