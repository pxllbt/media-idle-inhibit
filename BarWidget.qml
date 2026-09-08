// Media Idle Inhibit - Omarchy bar widget
//
// Author:  pxllbt (https://github.com/pxllbt)
// Repo:    https://github.com/pxllbt/media-idle-inhibit
// License: MIT - see LICENSE.
//
// Shows a small pill while any player is actively playing, sourced from the
// plugin's service over IPC. It is purely informational: toggling is done by
// the service, not by this widget.
import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.pxllbt.media-idle-inhibit"

  property string playerName: ""
  property string lastError: ""
  property bool toggleInFlight: false

  readonly property var _svc: root.bar && root.bar.shell && root.bar.shell.serviceFor
      ? root.bar.shell.serviceFor("io.github.pxllbt.media-idle-inhibit") : null

  on_SvcChanged: syncFromService()
  Component.onCompleted: syncFromService()

  function syncFromService() {
    var s = root._svc
    if (!s) {
      root.playerName = ""
      root.lastError = ""
      root.toggleInFlight = false
      return
    }
    root.playerName = String(s.activePlayerName || "")
    root.lastError = String(s.lastError || "")
    root.toggleInFlight = s.toggleInFlight === true
  }

  // Keep the pill in sync while it is attached to the bar.
  Connections {
    target: root._svc
    function onActivePlayerNameChanged() { root.syncFromService() }
    function onLastErrorChanged() { root.syncFromService() }
    function onToggleInFlightChanged() { root.syncFromService() }
  }

  readonly property bool mediaPlaying: root._svc ? root._svc.mediaPlaying === true : false
  readonly property string pillLabel: root.playerName ? root.playerName.toUpperCase() : "MEDIA"

  readonly property string tooltipText: !root.mediaPlaying
    ? "No active media"
    : (root.toggleInFlight
      ? "Idle inhibit pending…"
      : ("Idle inhibited: " + root.pillLabel
         + (root.lastError ? "\nError: " + root.lastError : "")))

  visible: root.mediaPlaying
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.mediaPlaying
    text: "\u266A " + root.pillLabel
    tooltipText: root.tooltipText
    onPressed: function(b) {
      if (root.bar) root.bar.showTooltip(button, root.tooltipText)
    }
  }
}