import QtQuick
import Quickshell.Io

Item {
  property var shell: null
  Process { running: true; command: ["magi-thermal-alert", "monitor"] }
}
