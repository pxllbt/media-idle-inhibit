pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

Ui.Panel {
  id: root

  moduleName: "io.github.pxllbt.media-idle-inhibit"
  manageIpc: false
  HostTokens { id: hostTokens; bar: root.bar }

  readonly property var idleService: bar && bar.shell
    && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor("io.github.pxllbt.media-idle-inhibit") : null
  readonly property bool mediaPlaying: idleService
    ? idleService.mediaPlaying === true : false
  readonly property string playerName: idleService
    ? String(idleService.activePlayerName || "") : ""
  readonly property string lastError: idleService
    ? String(idleService.lastError || "") : ""
  readonly property date lastToggle: idleService ? idleService.lastToggle : new Date(0)
  readonly property bool toggleInFlight: idleService
    ? idleService.toggleInFlight === true : false

  readonly property var tokens: bar && "visualTokens" in bar
    && bar.visualTokens ? bar.visualTokens : hostTokens
  readonly property color widgetInk: tokens
    && typeof tokens.widgetContentColor === "function"
    ? tokens.widgetContentColor(settings,
      bar ? bar.urgent : Commons.Color.accent)
    : (bar ? bar.urgent : Commons.Color.accent)
  readonly property string tooltipText: !root.mediaPlaying
    ? "No active media"
    : (root.toggleInFlight
       ? "Idle inhibit pending…"
       : ("Idle inhibited — " + (root.playerName || "MEDIA")
          + (root.lastError ? "\nError: " + root.lastError : "")))

  visible: root.mediaPlaying
  implicitWidth: visible ? (bar && bar.vertical
    ? bar.barSize : mediaSurface.implicitWidth) : 0
  implicitHeight: visible
    ? (bar && bar.vertical ? mediaSurface.implicitHeight : bar ? bar.barSize : 28) : 0

  Item {
    id: mediaSurface
    anchors.centerIn: parent
    implicitWidth: !root.tokens ? 0 : root.bar && root.bar.vertical
      ? root.bar.barSize
      : content.implicitWidth + 2 * root.tokens.pillPaddingX
    implicitHeight: !root.tokens ? 0 : root.bar && root.bar.vertical
      ? content.implicitHeight + Commons.Style.space(10)
      : root.tokens.slotHeight
    width: implicitWidth
    height: implicitHeight

    Loader {
      anchors.fill: parent
      anchors.topMargin: root.tokens
        ? Math.round((parent.height - root.tokens.pillHeight) / 2) : 0
      anchors.bottomMargin: root.tokens
        ? Math.round((parent.height - root.tokens.pillHeight) / 2) : 0
      active: root.bar !== null && root.tokens !== null
      sourceComponent: Component {
        PillSurface {
          tokenSource: root.tokens
          settings: root.settings
          v1AppearanceEnabled: true
          anchors.fill: parent
          bar: root.bar
        }
      }
    }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: root.tokens ? root.tokens.compactGap : Commons.Style.space(4)

      IconText {
        anchors.verticalCenter: parent.verticalCenter
        text: "graphic_eq"
        color: root.widgetInk
        font.pixelSize: root.tokens ? root.tokens.iconSize : 14
        fill: 1
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.playerName ? root.playerName.toUpperCase() : "MEDIA"
        color: root.widgetInk
        font.family: root.bar ? root.bar.fontFamily : Commons.Style.font.family
        font.pixelSize: root.tokens ? root.tokens.labelSize : Commons.Style.font.body
        font.weight: Font.Medium
        renderType: Text.NativeRendering
      }
    }

    Ui.WidgetButton {
      id: actionButton
      anchors.fill: parent
      bar: root.mediaPlaying ? root.bar : null
      text: " "
      keepSpace: true
      horizontalMargin: 0
      verticalPadding: 0
      fixedWidth: mediaSurface.width
      fixedHeight: mediaSurface.height
      tooltipText: root.tooltipText
      onPressed: function(button) {
        if (root.bar) root.bar.showTooltip(button, root.tooltipText)
      }
    }
  }
}
