import QtQuick

Item {
  id: root
  property bool active: false
  property bool critical: false
  property color cueColor: "#9cf23a"
  property int cueWidth: 3

  MotionState { id: motion }

  width: cueWidth
  opacity: active ? 1 : 0
  visible: opacity > 0

  // Critical state is synchronous. Noncritical changes receive one short
  // transition; there are no loops, travel, scale, or layout mutations.
  Behavior on opacity {
    enabled: !root.critical && !motion.off
    NumberAnimation { duration: motion.reduced ? 80 : 140; easing.type: Easing.OutCubic }
  }

  Rectangle {
    anchors.fill: parent
    color: root.cueColor
    Behavior on color {
      enabled: !root.critical && !motion.off
      ColorAnimation { duration: motion.reduced ? 80 : 140 }
    }
  }
}
