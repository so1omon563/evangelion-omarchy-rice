import QtQuick
import Quickshell
import Quickshell.Io
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
  readonly property string album: player ? (player.trackAlbum || "") : ""
  readonly property string glyph: player && player.isPlaying ? "󰎆" : "󰏤"
  readonly property bool compactBar: bar && !bar.vertical && bar.width < 1600
  property bool allowRemoteArtwork: false
  property int volumeStep: 5
  property int sourceCursor: 0
  property bool popupOpen: false

  function close() { popupOpen = false }
  function loadPreferences(raw) {
    try {
      var value = JSON.parse(String(raw))
      allowRemoteArtwork = value.artwork && value.artwork.allow_remote === true
      volumeStep = Math.max(1, Math.min(20, Number(value.volume_step_percent || 5)))
    } catch (error) { allowRemoteArtwork = false; volumeStep = 5 }
  }
  function artworkSource(url) {
    var value = String(url || "")
    if (!value) return ""
    if (value.indexOf("file:") === 0 || value.indexOf("image:") === 0 || value.indexOf("qrc:") === 0 || value.charAt(0) === "/") return value
    return allowRemoteArtwork && (value.indexOf("https://") === 0 || value.indexOf("http://") === 0) ? value : ""
  }
  function formatTime(value) {
    var seconds = Math.max(0, Math.floor(Number(value || 0)))
    return String(Math.floor(seconds / 60)).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0")
  }
  function progress() { return player && player.length > 0 ? Math.max(0, Math.min(1, player.position / player.length)) : 0 }
  function activeSourceIndex() {
    if (!player || !media) return 0
    var key = media.playerKey(player)
    for (var i = 0; i < sources.length; i++) if (media.playerKey(sources[i]) === key) return i
    return 0
  }
  function openPanel() { popupOpen = true; sourceCursor = activeSourceIndex(); forceActiveFocus() }
  function selectCursor() {
    if (!media || !sources.length) return
    sourceCursor = (sourceCursor + sources.length) % sources.length
    media.selectPlayer(media.playerKey(sources[sourceCursor]))
  }
  function moveSource(delta) { if (sources.length) { sourceCursor = (sourceCursor + delta + sources.length) % sources.length; selectCursor() } }
  function changeVolume(delta) {
    if (!player || player.volume === undefined) return
    player.volume = Math.max(0, Math.min(1, Number(player.volume) + delta * volumeStep / 100))
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/media.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadPreferences(text())
    onFileChanged: reload()
    onLoadFailed: root.loadPreferences("{}")
  }

  visible: hasMedia
  implicitWidth: hasMedia ? (bar && bar.vertical ? barSize : Style.space(compactBar ? 116 : 190)) : 0
  implicitHeight: barSize
  focus: popupOpen
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (!popupOpen) return
    if (event.key === Qt.Key_Escape) close()
    else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) moveSource(-1)
    else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) moveSource(1)
    else if (event.key === Qt.Key_Space) media.runAction("playPause", true)
    else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) media.runAction("previous", true)
    else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) media.runAction("next", true)
    else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) changeVolume(1)
    else if (event.key === Qt.Key_Minus) changeVolume(-1)
    else return
    event.accepted = true
  }

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
      width: root.compactBar ? Style.space(82) : Style.space(150)
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

  Motion.StateCue {
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    active: root.player && root.player.isPlaying
    cueColor: Color.accent
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (!root.media) return
      if (mouse.button === Qt.LeftButton) { if (root.popupOpen) root.close(); else root.openPanel() }
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
    contentWidth: fittedContentWidth(Style.space(370))
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
            source: root.artworkSource(root.player ? root.player.trackArtUrl : "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: source !== ""
          }
          Text {
            anchors.centerIn: parent
            visible: root.artworkSource(root.player ? root.player.trackArtUrl : "") === ""
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
            text: root.album || "NO ALBUM METADATA"
            color: Qt.darker(root.bar.foreground, 1.55)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
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

      Column {
        width: parent.width
        spacing: Style.space(3)
        Row {
          width: parent.width
          Text { text: root.formatTime(root.player ? root.player.position : 0); color: Qt.darker(root.bar.foreground, 1.35); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
          Item { width: parent.width - Style.space(116); height: 1 }
          Text { text: root.formatTime(root.player ? root.player.length : 0); color: Qt.darker(root.bar.foreground, 1.35); font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption }
        }
        Rectangle {
          width: parent.width; height: Style.space(4); color: Style.normalFillFor(root.bar.foreground, Color.accent)
          Rectangle { width: parent.width * root.progress(); height: parent.height; color: Color.accent }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)
        Button { iconText: "󰒮"; foreground: root.bar.foreground; onClicked: root.media.runAction("previous", true) }
        Button { iconText: root.player && root.player.isPlaying ? "󰏤" : "󰐊"; foreground: root.bar.foreground; onClicked: root.media.runAction("playPause", true) }
        Button { iconText: "󰒭"; foreground: root.bar.foreground; onClicked: root.media.runAction("next", true) }
        Item { width: parent.width - Style.space(190); height: 1 }
        Text { anchors.verticalCenter: parent.verticalCenter; text: root.player && root.player.volume !== undefined ? "VOL " + Math.round(root.player.volume * 100) + "%" : "VOL N/A"; color: "#62d8ff"; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
      }

      PanelSeparator { visible: root.sources.length > 1; foreground: root.bar.foreground }

      Repeater {
        model: root.sources
        BorderSurface {
          required property var modelData
          required property int index
          readonly property bool selected: root.player && root.media.playerKey(root.player) === root.media.playerKey(modelData)
          readonly property bool cursor: index === root.sourceCursor
          width: panel.width
          height: sourceText.implicitHeight + Style.space(10)
          color: selected ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
          borderSpec: selected || cursor ? Border.controlSpec("normal", root.bar.foreground, selected ? Color.accent : "#62d8ff") : Border.none()
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

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "↑↓ SOURCE  ·  SPACE PLAY  ·  ←→ TRACK  ·  +/- VOLUME  ·  ESC CLOSE"
        color: Qt.darker(root.bar.foreground, 1.6)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }
}
