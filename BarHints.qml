pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import "Placement.js" as Placement

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property bool opened: false
  property var activeScreen: null
  property string typed: ""
  property string query: ""
  property var allHints: []
  property var hints: []
  readonly property int hintLimit: 99
  readonly property int slotLimit: 512
  readonly property int idLengthLimit: 128
  readonly property int nameLengthLimit: 80
  readonly property int screenLimit: 32
  readonly property int kindLimit: 16
  readonly property int hintDigits: Math.max(1, String(hints.length).length)
  readonly property int hintGap: 4
  readonly property string barPosition: {
    const value = shell && shell.bar && typeof shell.bar.position === "string"
      ? shell.bar.position : "top"
    return ["top", "bottom", "left", "right"].indexOf(value) >= 0 ? value : "top"
  }
  readonly property int barSize: {
    const value = shell && shell.bar ? shell.bar.barSize : 30
    return Placement.finiteNumber(value) && value > 0 && value <= 512 ? value : 30
  }

  function focusedScreen() {
    const monitor = Hyprland.focusedMonitor
    const name = monitor && typeof monitor.name === "string" ? monitor.name : ""
    const screens = Quickshell.screens
    if (!name || name.length > idLengthLimit || !screens
        || screens.length < 1 || screens.length > screenLimit) return null

    let match = null
    for (let i = 0; i < screens.length; i++) {
      const screen = screens[i]
      if (screen && typeof screen.name === "string" && screen.name === name) {
        if (match) return null
        match = screen
      }
    }
    return match
  }

  function canOpen(id) {
    const plugins = pluginRegistry && pluginRegistry.installedPlugins
    const plugin = plugins ? plugins[id] : null
    const kinds = plugin && Array.isArray(plugin.kinds) ? plugin.kinds : []
    if (kinds.length <= kindLimit) {
      for (let i = 0; i < kinds.length; i++)
        if (kinds[i] === "panel" || kinds[i] === "overlay" || kinds[i] === "menu")
          return true
    }
    try {
      return shell && shell.bar && typeof shell.bar.findPanelWidget === "function"
        && shell.bar.findPanelWidget(id) !== null
    } catch (e) {
      return false
    }
  }

  function displayName(id) {
    const plugins = pluginRegistry && pluginRegistry.installedPlugins
    const plugin = plugins ? plugins[id] : null
    const widget = plugin && plugin.barWidget ? plugin.barWidget : null
    const value = widget && typeof widget.displayName === "string"
      ? widget.displayName
      : plugin && typeof plugin.name === "string" ? plugin.name : id
    return Placement.safeName(value, id, nameLengthLimit)
  }

  function rebuildHints() {
    const bar = shell ? shell.bar : null
    const seen = []
    const next = []
    const slots = bar && Array.isArray(bar.moduleSlots) ? bar.moduleSlots : null
    const targetName = activeScreen && typeof activeScreen.name === "string"
      ? activeScreen.name : ""
    if (!bar || bar.barHidden === true || !slots || slots.length > slotLimit
        || !targetName || typeof bar.slotScreenName !== "function") {
      allHints = next
      hints = next
      return
    }

    const vertical = barPosition === "left" || barPosition === "right"
    for (let i = 0; i < slots.length; i++) {
      const slot = slots[i]
      const widget = slot ? slot.activeItem : null
      const id = Placement.safeId(slot ? slot.moduleName : null, idLengthLimit)
      const width = slot ? slot.width : NaN
      const height = slot ? slot.height : NaN
      let screenName = ""
      try { screenName = bar.slotScreenName(slot) } catch (e) {}
      if (!id || seen.indexOf(id) >= 0 || !widget || slot.visible !== true
          || widget.visible !== true || !Placement.finiteNumber(width)
          || !Placement.finiteNumber(height) || width <= 0 || height <= 0
          || typeof screenName !== "string" || screenName !== targetName
          || !canOpen(id)) continue

      let point = null
      try { point = slot.mapToItem(null, 0, 0) } catch (e) {}
      if (!point || !Placement.finiteNumber(point.x)
          || !Placement.finiteNumber(point.y)) continue
      const axis = vertical ? point.y + height / 2 : point.x + width / 2
      if (!Placement.finiteNumber(axis)) continue

      seen.push(id)
      next.push({
        id: id,
        name: displayName(id),
        axis: axis
      })
      if (next.length >= hintLimit) break
    }
    next.sort(function(a, b) { return a.axis - b.axis })
    allHints = next
    applyFilter()
  }

  function open() {
    close()
    activeScreen = focusedScreen()
    if (!activeScreen) return
    typed = ""
    rebuildHints()
    opened = hints.length > 0
    if (!opened) activeScreen = null
  }

  function close() {
    opened = false
    typed = ""
    query = ""
    allHints = []
    hints = []
    activeScreen = null
  }

  function dismiss() {
    close()
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "io.github.hanssound.bar-hints")
  }

  function hintLabel(index) {
    return ("000" + String(index + 1)).slice(-hintDigits)
  }

  function activate(index) {
    if (index < 0 || index >= hints.length) {
      typed = ""
      return
    }
    const id = Placement.safeId(hints[index].id, idLengthLimit)
    if (!id) {
      close()
      return
    }
    dismiss()
    Qt.callLater(function() {
      if (shell && typeof shell.summon === "function") shell.summon(id, "{}")
    })
  }

  function acceptDigit(digit) {
    typed += digit
    if (typed.length >= hintDigits) activate(parseInt(typed, 10) - 1)
  }

  function applyFilter() {
    hints = Placement.prefixMatches(allHints, query, hintLimit, nameLengthLimit)
    typed = ""
  }

  function acceptText(text) {
    const chunk = Placement.safeQuery(text, nameLengthLimit)
    if (!chunk) return false
    const next = Placement.safeQuery(query + chunk, nameLengthLimit)
    if (next === query) return false
    query = next
    applyFilter()
    return true
  }

  function backspace() {
    if (typed) {
      typed = typed.slice(0, -1)
    } else if (query) {
      query = query.slice(0, -1)
      applyFilter()
    }
  }

  Connections {
    target: Quickshell
    function onScreensChanged() { if (root.opened) root.dismiss() }
  }

  PanelWindow {
      id: overlay

      screen: root.activeScreen
      visible: root.opened && root.activeScreen !== null
      anchors { top: true; right: true; bottom: true; left: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "bar-hints"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: visible
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      onVisibleChanged: if (visible) {
        Qt.callLater(keyCatcher.forceActiveFocus)
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: overlay.visible

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.dismiss()
          } else if (event.key === Qt.Key_Backspace) {
            root.backspace()
          } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            root.acceptDigit(String(event.key - Qt.Key_0))
          } else if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier
                     | Qt.MetaModifier) || !root.acceptText(event.text)) {
            return
          }
          event.accepted = true
        }

        Rectangle {
          id: filterBox

          x: root.barPosition === "left"
            ? root.barSize + 12
            : root.barPosition === "right"
              ? overlay.width - root.barSize - width - 12
              : (overlay.width - width) / 2
          y: root.barPosition === "top"
            ? root.barSize + 12
            : root.barPosition === "bottom"
              ? overlay.height - root.barSize - height - 12
              : (overlay.height - height) / 2
          z: 1
          width: Math.max(180, Math.min(320, filterLabel.implicitWidth + 24))
          height: 40
          visible: root.query.length > 0
          radius: 8
          color: Qt.rgba(Color.menu.background.r,
                         Color.menu.background.g,
                         Color.menu.background.b, 0.98)
          border.color: Color.menu.selectedText
          border.width: 1
          Accessible.role: Accessible.StaticText
          Accessible.name: filterLabel.text

          Text {
            id: filterLabel

            anchors.fill: parent
            anchors.margins: 12
            text: "Filter: " + root.query + " · "
              + (root.hints.length === 0 ? "No matches"
                : root.hints.length + (root.hints.length === 1 ? " match" : " matches"))
            textFormat: Text.PlainText
            color: Color.menu.text
            font.family: Style.font.family
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }

        Repeater {
          model: root.hints

          delegate: Item {
            id: hintColumn
            required property var modelData
            required property int index

            readonly property string label: root.hintLabel(index)
            readonly property bool expanded: hoverArea.containsMouse
            readonly property point badgePoint: Placement.badgePoint(
              root.barPosition, modelData.axis, overlay.width, overlay.height,
              root.barSize, root.hintGap, width, height)
            x: badgePoint.x
            y: badgePoint.y
            width: 26
            height: 24
            Accessible.role: Accessible.Button
            Accessible.name: "Open " + modelData.name + " with " + label

            Rectangle {
              id: badge
              anchors.fill: parent
              radius: 5
              color: Qt.rgba(Color.menu.background.r,
                             Color.menu.background.g,
                             Color.menu.background.b, 1)
              border.color: Qt.rgba(Color.menu.selectedText.r,
                                    Color.menu.selectedText.g,
                                    Color.menu.selectedText.b, 1)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: hintColumn.label
                color: Qt.rgba(Color.menu.text.r,
                               Color.menu.text.g,
                               Color.menu.text.b, 1)
                font.family: Style.font.family
                font.pixelSize: 13
                font.bold: true
              }
            }

            Rectangle {
              id: nameBubble
              width: 150
              height: 30
              x: root.barPosition === "left" ? badge.width + root.hintGap
                : root.barPosition === "right" ? -width - root.hintGap
                : Math.max(4, Math.min(overlay.width - width - 4,
                    hintColumn.x + (badge.width - width) / 2)) - hintColumn.x
              y: root.barPosition === "top" ? badge.height + root.hintGap
                : root.barPosition === "bottom" ? -height - root.hintGap
                : Math.max(4, Math.min(overlay.height - height - 4,
                    hintColumn.y + (badge.height - height) / 2)) - hintColumn.y
              visible: hintColumn.expanded
              radius: 5
              color: Color.menu.background
              border.color: Color.menu.border
              border.width: 1
              opacity: 0.96

              Text {
                anchors.fill: parent
                anchors.margins: 8
                text: modelData.name
                textFormat: Text.PlainText
                color: Color.menu.text
                font.family: Style.font.family
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }

            MouseArea {
              id: hoverArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activate(hintColumn.index)
            }
          }
        }
      }
  }
}
