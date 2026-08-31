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
  property string activeScreenName: ""
  property string typed: ""
  property var hints: []
  readonly property int hintDigits: Math.max(1, String(hints.length).length)
  readonly property int hintGap: 4
  readonly property string barPosition: {
    const value = shell && shell.bar ? String(shell.bar.position || "top") : "top"
    return ["top", "bottom", "left", "right"].indexOf(value) >= 0 ? value : "top"
  }
  readonly property int barSize: shell && shell.bar ? Number(shell.bar.barSize) || 30 : 30

  function focusedScreenName() {
    return Hyprland.focusedMonitor
      ? String(Hyprland.focusedMonitor.name || "") : ""
  }

  function canOpen(id) {
    const plugins = pluginRegistry && pluginRegistry.installedPlugins
    const plugin = plugins ? plugins[id] : null
    const kinds = plugin && Array.isArray(plugin.kinds) ? plugin.kinds : []
    if (kinds.indexOf("panel") >= 0 || kinds.indexOf("overlay") >= 0
        || kinds.indexOf("menu") >= 0) return true
    return shell && shell.bar && typeof shell.bar.findPanelWidget === "function"
      && shell.bar.findPanelWidget(id) !== null
  }

  function displayName(id) {
    const plugins = pluginRegistry && pluginRegistry.installedPlugins
    const plugin = plugins ? plugins[id] : null
    const widget = plugin && plugin.barWidget ? plugin.barWidget : null
    return String(widget && widget.displayName
      || plugin && plugin.name || id)
  }

  function rebuildHints() {
    const bar = shell ? shell.bar : null
    const seen = ({})
    const next = []
    if (!bar || bar.barHidden === true) {
      hints = next
      return
    }

    const vertical = barPosition === "left" || barPosition === "right"
    const slots = bar.moduleSlots || []
    for (let i = 0; i < slots.length; i++) {
      const slot = slots[i]
      const widget = slot ? slot.activeItem : null
      const id = String(slot && slot.moduleName || "")
      const screenName = slot && typeof bar.slotScreenName === "function"
        ? String(bar.slotScreenName(slot) || "") : ""
      if (!id || seen[id] || !widget || slot.visible !== true
          || widget.visible !== true || slot.width <= 0 || slot.height <= 0
          || !canOpen(id)) continue
      if (screenName && activeScreenName && screenName !== activeScreenName) continue

      let point = { x: Number(slot.x) || 0, y: Number(slot.y) || 0 }
      try { point = slot.mapToItem(null, 0, 0) } catch (e) {}
      seen[id] = true
      next.push({
        id: id,
        name: displayName(id),
        axis: vertical
          ? (Number(point.y) || 0) + Number(slot.height) / 2
          : (Number(point.x) || 0) + Number(slot.width) / 2
      })
    }
    next.sort(function(a, b) { return a.axis - b.axis })
    hints = next
  }

  function open() {
    activeScreenName = focusedScreenName()
    typed = ""
    rebuildHints()
    opened = hints.length > 0
  }

  function close() {
    opened = false
    typed = ""
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
    const id = hints[index].id
    dismiss()
    Qt.callLater(function() {
      if (shell && typeof shell.summon === "function") shell.summon(id, "{}")
    })
  }

  function acceptDigit(digit) {
    typed += digit
    if (typed.length >= hintDigits) activate(parseInt(typed, 10) - 1)
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: overlay
      required property var modelData

      screen: modelData
      visible: root.opened
        && (!root.activeScreenName
          || String(modelData.name || "") === root.activeScreenName)
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
            root.typed = root.typed.slice(0, -1)
          } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            root.acceptDigit(String(event.key - Qt.Key_0))
          } else {
            return
          }
          event.accepted = true
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
}
