import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "rob.vitals"

  // ---- which metrics to show (per-widget settings in shell.json) ----------
  // Values may arrive as JSON booleans (popup/--json) or strings (plain
  // `omarchy bar set`), so parse both.
  function shown(key) {
    var v = setting(key, true)
    return v === true || v === "true" || v === 1 || v === "1"
  }

  readonly property bool showCpu: shown("showCpu")
  readonly property bool showMem: shown("showMem")
  readonly property bool showDisk: shown("showDisk")
  readonly property bool anyShown: showCpu || showMem || showDisk

  // Display order of the metrics, as an array of keys ("cpu"/"mem"/"disk").
  // Managed from the settings popup (drag to reorder) and persisted to
  // shell.json like the show flags.
  readonly property var metricOrder: root.setting("metricOrder", ["cpu", "mem", "disk"])

  function metricShown(key) {
    return root.shown("show" + key.charAt(0).toUpperCase() + key.slice(1))
  }

  function metricIcon(key) {
    if (key === "cpu") return ""
    if (key === "mem") return ""
    if (key === "disk") return "󰋊"
    return ""
  }

  function metricLabel(key) {
    if (key === "cpu") return "CPU usage"
    if (key === "mem") return "Memory usage"
    if (key === "disk") return "Disk usage"
    return ""
  }

  function metricDescription(key) {
    if (key === "cpu") return "Processor load"
    if (key === "mem") return "RAM in use"
    if (key === "disk") return "Root filesystem"
    return ""
  }

  function metricValue(key) {
    if (key === "cpu") return root.cpu
    if (key === "mem") return root.mem
    if (key === "disk") return root.disk
    return null
  }

  function orderedMetrics(onlyShown) {
    var out = []
    var order = root.metricOrder
    for (var i = 0; i < order.length; i++) {
      var key = order[i]
      if (key !== "cpu" && key !== "mem" && key !== "disk") continue
      if (onlyShown && !root.metricShown(key)) continue
      out.push(key)
    }
    return out
  }

  readonly property var visibleMetrics: root.orderedMetrics(true)

  readonly property int intervalSeconds: Math.max(1, Math.min(10, Number(setting("intervalSeconds", 2)) || 2))

  readonly property string chipIcon: "󰍛" // nf-md-memory

  // ---- live data ------------------------------------------------------------
  property var snapshot: null
  readonly property var cpu: snapshot ? snapshot.cpu : null
  readonly property var mem: snapshot ? snapshot.mem : null
  readonly property var disk: snapshot ? snapshot.disk : null

  readonly property string collectorPath: Qt.resolvedUrl("vitals-collector.py").toString().replace(/^file:\/\//, "")

  function ingest(line) {
    var raw = String(line || "").trim()
    if (!raw) return
    var parsed
    try { parsed = JSON.parse(raw) } catch (e) { return }
    if (!parsed || (parsed.cpu === undefined && parsed.mem === undefined && parsed.disk === undefined)) return
    root.snapshot = parsed
  }

  function pct(v) {
    return v === null || v === undefined ? "–" : Math.round(v) + "%"
  }

  function cellColor(v) {
    if (v !== null && v !== undefined && v >= 85)
      return root.bar && root.bar.urgent !== undefined ? root.bar.urgent : Color.urgent
    return root.foreground
  }

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property real cellSize: Style.font.body
  // Match WidgetButton's horizontalMargin so the widget keeps the same
  // breathing room as its neighbours instead of butting against them.
  readonly property real hMargin: Style.spaceReal(8.5)

  // ---- settings popup plumbing ----------------------------------------------
  readonly property bool opened: settingsLoader.item ? settingsLoader.item.opened === true : false

  function open() {
    if (settingsLoader.item && settingsLoader.item.open) settingsLoader.item.open()
  }

  function close() {
    if (settingsLoader.item && settingsLoader.item.close) settingsLoader.item.close()
  }

  function togglePanel() {
    if (settingsLoader.item && settingsLoader.item.toggle) settingsLoader.item.toggle()
  }

  // The bar routes clicks through registered click targets (it calls
  // triggerPress), so register this widget like a WidgetButton does.
  property var registeredBar: null

  function triggerPress(button) {
    root.togglePanel()
  }

  function syncClickRegistration() {
    if (root.registeredBar && root.registeredBar.unregisterClickTarget) root.registeredBar.unregisterClickTarget(root)
    root.registeredBar = root.bar
    if (root.registeredBar && root.registeredBar.registerClickTarget) root.registeredBar.registerClickTarget(root)
  }

  onBarChanged: {
    root.syncClickRegistration()
    root.injectSettings()
  }
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (root.registeredBar && root.registeredBar.unregisterClickTarget) root.registeredBar.unregisterClickTarget(root)

  // Bar popout contract: the widget stands in for the nested popup.
  readonly property bool popoutSwitchClosing: settingsLoader.item ? settingsLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (settingsLoader.item && settingsLoader.item.closeForPopoutSwitch) settingsLoader.item.closeForPopoutSwitch()
  }

  // Persist a per-widget setting: apply locally so the bar redraws on the
  // click itself, then write it back into shell.json (same pattern as the
  // first-party clock panel).
  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (var key in values) entry[key] = values[key]

    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function toggleMetric(key) {
    var values = {}
    values[key] = !root.shown(key)
    root.persistSettings(values)
  }

  function setMetricOrder(order) {
    root.persistSettings({ metricOrder: order })
  }

  function injectSettings() {
    var target = settingsLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("anchorItem" in target) target.anchorItem = root
    if ("hostWidget" in target) target.hostWidget = root
  }

  Loader {
    id: settingsLoader
    active: true
    source: Qt.resolvedUrl("Settings.qml")
    visible: false
    onLoaded: {
      root.injectSettings()
      Qt.callLater(root.injectSettings)
    }
  }

  // ---- collector --------------------------------------------------------------
  Process {
    id: collector
    command: ["python3", root.collectorPath, "--interval", String(root.intervalSeconds)]
    running: true
    stdout: SplitParser {
      onRead: function(line) { root.ingest(line) }
    }
  }

  // ---- surface -----------------------------------------------------------------
  implicitWidth: root.anyShown ? row.implicitWidth : iconButton.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal

  Row {
    id: row
    visible: root.anyShown
    spacing: Style.space(6)
    leftPadding: root.hMargin
    rightPadding: root.hMargin
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
      model: root.visibleMetrics

      Row {
        required property string modelData
        spacing: Style.space(3)
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: root.metricIcon(modelData)
          color: root.cellColor(root.metricValue(modelData))
          font.family: root.fontFamily
          font.pixelSize: root.cellSize
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: root.pct(root.metricValue(modelData))
          color: root.cellColor(root.metricValue(modelData))
          font.family: root.fontFamily
          font.pixelSize: root.cellSize
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  BarIconButton {
    id: iconButton
    visible: !root.anyShown
    bar: root.bar
    text: root.chipIcon
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Vitals"
    onPressed: root.togglePanel()
  }
}