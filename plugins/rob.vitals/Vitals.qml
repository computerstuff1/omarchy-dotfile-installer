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

    Row {
      visible: root.showCpu
      spacing: Style.space(3)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: ""
        color: root.cellColor(root.cpu)
        font.family: root.fontFamily
        font.pixelSize: root.cellSize
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.pct(root.cpu)
        color: root.cellColor(root.cpu)
        font.family: root.fontFamily
        font.pixelSize: root.cellSize
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Row {
      visible: root.showMem
      spacing: Style.space(3)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: ""
        color: root.cellColor(root.mem)
        font.family: root.fontFamily
        font.pixelSize: root.cellSize
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.pct(root.mem)
        color: root.cellColor(root.mem)
        font.family: root.fontFamily
        font.pixelSize: root.cellSize
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Row {
      visible: root.showDisk
      spacing: Style.space(3)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: "󰋊"
        color: root.cellColor(root.disk)
        font.family: root.fontFamily
        font.pixelSize: root.cellSize
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.pct(root.disk)
        color: root.cellColor(root.disk)
        font.family: root.fontFamily
        font.pixelSize: root.cellSize
        anchors.verticalCenter: parent.verticalCenter
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