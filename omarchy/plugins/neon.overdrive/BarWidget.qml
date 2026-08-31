import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var bar: null
  property string moduleName: "neon.overdrive"
  property var settings: ({})
  property var levels: [2,4,7,10,13,16,18,20,18,16,13,10,7,4,2,1]
  property var neonSettings: ({})
  readonly property bool cavaEnabled: neonSettings.cava !== false
  readonly property real sensitivity: neonSettings.sensitivity === undefined ? 1.0 : Number(neonSettings.sensitivity)
  implicitWidth: bar && bar.vertical ? bar.barSize : 150
  implicitHeight: bar ? bar.barSize : 30

  function ingest(line) {
    var raw = String(line).trim().split(";")
    var next = []
    for (var i = 0; i < raw.length && i < 28; i++) {
      var value = Number(raw[i])
      if (!isNaN(value)) next.push(Math.max(1, Math.min(100, value * sensitivity)))
    }
    if (next.length) { levels = next; spectrum.requestPaint() }
  }

  function loadSettings(content) {
    try { neonSettings = JSON.parse(String(content || "{}")) || {} }
    catch (e) { console.warn("neon-overdrive bar: invalid settings", e) }
    spectrum.requestPaint()
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/neon-overdrive.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadSettings(text())
    onFileChanged: reload()
  }

  Process {
    running: root.cavaEnabled
    command: [Quickshell.env("HOME") + "/.local/bin/cava", "-p", Quickshell.env("HOME") + "/.config/omarchy/plugins/neon.overdrive/cava.conf"]
    stdout: SplitParser { onRead: function(line) { root.ingest(line) } }
  }

  Canvas {
    id: spectrum
    anchors.fill: parent
    anchors.margins: 4
    antialiasing: true
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (!root.cavaEnabled) {
        ctx.fillStyle = "#9CF23A"
        ctx.fillRect(0, height - 2, width, 2)
        return
      }
      var count = root.levels.length
      if (!count) return
      var gap = 1.5
      var bw = Math.max(1.5, (width - gap * (count - 1)) / count)
      for (var i = 0; i < count; i++) {
        var h = Math.max(2, (root.levels[i] / 100) * height)
        var x = i * (bw + gap)
        var g = ctx.createLinearGradient(0, height, 0, height - h)
        g.addColorStop(0, "#4B286D")
        g.addColorStop(0.48, "#8F4BC8")
        g.addColorStop(0.76, "#9CF23A")
        g.addColorStop(1, "#F28C28")
        ctx.fillStyle = g
        ctx.shadowColor = i % 3 === 0 ? "#9CF23A" : "#8F4BC8"
        ctx.shadowBlur = 4
        ctx.fillRect(x, height - h, bw, h)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: if (root.bar) root.bar.showTooltip(root, "SYNCHRONIZATION · live audio spectrum")
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: if (root.bar) root.bar.run("xdg-terminal-exec cava")
  }
}
