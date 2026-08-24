import QtQuick
import qs.Commons
import qs.Ui

// Settings popup for rob.vitals: a Toggle row per metric. Flipping a switch
// persists the choice through the host widget (updateEntryInline), so the bar
// redraws immediately and the choice survives restarts.
//
// Wraps a PopupCard because PopupCard declares `bar`/`anchorItem` as required
// properties; loaded via a Loader, they are only known once the host widget
// injects them, so the required check would fail at construction. An Item root
// with defaults lets the Loader succeed and the PopupCard bindings update when
// the host injects bar/anchorItem after load.
Item {
  id: root

  // Injected by the host widget after load (bar may be null until then).
  property var bar: null
  property var anchorItem: null
  property var hostWidget: null

  readonly property bool opened: card.open

  function show() { card.open = true }
  function toggle() { card.open = !card.open }
  function close() { card.close() }
  function closeForPopoutSwitch() { card.open = false }
  readonly property bool popoutSwitchClosing: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function metricShown(key) {
    return hostWidget ? hostWidget.shown(key) : true
  }

  function toggleMetric(key) {
    if (hostWidget) hostWidget.toggleMetric(key)
  }

  PopupCard {
    id: card
    anchorItem: root.anchorItem
    bar: root.bar

    contentWidth: Style.space(272)
    contentHeight: Style.space(238)

    Column {
      width: parent.width
      spacing: Style.space(10)

      Text {
        text: "VITALS"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
      }

      Toggle {
        label: "CPU usage"
        description: "Processor load"
        checked: root.metricShown("showCpu")
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleMetric("showCpu")
      }

      Toggle {
        label: "Memory usage"
        description: "RAM in use"
        checked: root.metricShown("showMem")
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleMetric("showMem")
      }

      Toggle {
        label: "Disk usage"
        description: "Root filesystem"
        checked: root.metricShown("showDisk")
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleMetric("showDisk")
      }
    }
  }
}