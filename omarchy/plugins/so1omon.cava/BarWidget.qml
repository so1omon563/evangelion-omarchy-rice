import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "so1omon.cava"
  property bool cavaAvailable: false
  property var levels: [3,5,8,12,17,22,16,11,7,4,4,7,11,16,22,17,12,8]

  visible: cavaAvailable
  implicitWidth: cavaAvailable ? (bar && bar.vertical ? barSize : Style.space(126)) : 0
  implicitHeight: barSize

  function ingest(line) {
    var raw = String(line).trim().split(";")
    var next = []
    for (var i = 0; i < raw.length && i < 24; i++) {
      var value = Number(raw[i])
      if (!isNaN(value)) next.push(Math.max(1, Math.min(100, value)))
    }
    if (next.length) { levels = next; spectrum.requestPaint() }
  }

  Process {
    id: detector
    running: true
    command: ["bash", "-lc", "command -v cava >/dev/null && echo yes || echo no"]
    stdout: SplitParser { onRead: function(line) { root.cavaAvailable = String(line).trim() === "yes" } }
  }

  Process {
    running: root.cavaAvailable
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/omarchy/plugins/so1omon.cava/cava.conf"]
    stdout: SplitParser { onRead: function(line) { root.ingest(line) } }
  }

  Canvas {
    id: spectrum
    anchors.fill: parent
    anchors.margins: Style.space(3)
    antialiasing: true
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var count = root.levels.length
      if (!count) return
      var gap = 1.5
      var barWidth = Math.max(1.5, (width - gap * (count - 1)) / count)
      for (var i = 0; i < count; i++) {
        var level = Math.max(2, root.levels[i] / 100 * height)
        var x = i * (barWidth + gap)
        var gradient = ctx.createLinearGradient(0, height, 0, height - level)
        gradient.addColorStop(0, String(Color.muted))
        gradient.addColorStop(0.55, String(Color.accent))
        gradient.addColorStop(1, String(root.bar.urgent))
        ctx.fillStyle = gradient
        ctx.shadowColor = String(i % 3 === 0 ? Color.accent : Color.muted)
        ctx.shadowBlur = 4
        ctx.fillRect(x, height - level, barWidth, level)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, "MAGI SYNCHRONIZATION // live audio spectrum")
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: if (root.bar) root.bar.run("xdg-terminal-exec cava")
  }
}
