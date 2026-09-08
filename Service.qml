pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property bool ready: shell !== null

  property bool mediaPlaying: false
  property string activePlayerName: ""
  property string lastError: ""
  property string lastToggleValue: ""
  property date lastToggle: new Date(0)
  property bool toggleInFlight: false
  property bool pendingToggleOn: false
  property bool hasPendingToggle: false

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateDir: root.home + "/.local/state/omarchy/indicators"
  readonly property string ownerMarker: root.stateDir + "/stay-awake.media"

  readonly property var enableCommand: [
    "bash", "-lc",
    "d=\"$HOME/.local/state/omarchy/indicators\"; mkdir -p \"$d\"; " +
    "if command -v omarchy-toggle-idle >/dev/null 2>&1; then " +
    "  omarchy-toggle-idle stay-awake; " +
    "else touch \"$d/stay-awake\"; fi; " +
    "touch \"$d/stay-awake.media\" " +
    "|| { echo \"failed to enable media idle inhibit\"; exit 1; }"
  ]

  readonly property var disableCommand: [
    "bash", "-lc",
    "d=\"$HOME/.local/state/omarchy/indicators\"; m=\"$d/stay-awake.media\"; s=\"$d/stay-awake\"; " +
    "if [[ ! -f $m ]]; then exit 0; fi; " +
    "if [[ ! -f $s ]]; then rm -f \"$m\"; exit 0; fi; " +
    "if [[ -f $s && $(stat -c %Y \"$m\" 2>/dev/null || echo 0) -ge $(stat -c %Y \"$s\" 2>/dev/null || echo 0) ]]; then " +
    "  if command -v omarchy-toggle-idle >/dev/null 2>&1; then " +
    "    if omarchy-toggle-idle allow-idle; then rm -f \"$m\"; else echo \"failed to allow idle\"; exit 1; fi; " +
    "  else rm -f \"$s\"; rm -f \"$m\"; fi; " +
    "else exit 0; fi"
  ]

  function currentPlayingPlayer() {
    if (!Mpris.players) return null
    const players = Mpris.players.values || []
    for (let i = 0; i < players.length; i++) {
      const p = players[i]
      if (p && p.isPlaying === true) return p
    }
    return null
  }

  function applyToggle(enable) {
    root.pendingToggleOn = !!enable
    root.hasPendingToggle = true
    root.flushToggle()
  }

  function flushToggle() {
    if (toggleProcess.running) return
    if (!root.hasPendingToggle) return

    const enable = root.pendingToggleOn
    root.hasPendingToggle = false
    root.toggleInFlight = true
    root.lastError = ""
    root.lastToggleValue = enable ? "on" : "off"
    toggleProcess.command = enable ? root.enableCommand : root.disableCommand
    toggleProcess.running = true
  }

  function recalc() {
    const wasPlaying = root.mediaPlaying
    const player = root.currentPlayingPlayer()
    const nowPlaying = player !== null
    const nextName = player
      ? String(player.desktopEntry || player.identity || "media") : ""

    if (wasPlaying !== nowPlaying) {
      root.mediaPlaying = nowPlaying
      root.activePlayerName = nextName
      root.applyToggle(nowPlaying)
    } else if (nowPlaying && root.activePlayerName !== nextName) {
      root.activePlayerName = nextName
    }
  }

  function diagnosticStatus() {
    return {
      mediaPlaying: root.mediaPlaying,
      activePlayerName: root.activePlayerName,
      lastToggle: root.lastToggle.toISOString(),
      lastToggleValue: root.lastToggleValue,
      lastError: root.lastError,
      toggleInFlight: root.toggleInFlight
    }
  }

  Component.onCompleted: {
    root.recalc()
    // Self-heal any stale owner marker left by a crash or restart while no
    // media was playing. The disable path is a no-op unless we own it.
    if (!root.mediaPlaying) root.applyToggle(false)
  }

  // Model-level changes cover players appearing and disappearing.
  Connections {
    target: Mpris.players
    function onRowsInserted() { root.recalc() }
    function onRowsRemoved() { root.recalc() }
    function onModelReset() { root.recalc() }
  }

  // Play/pause flips happen on an already-known player without touching the
  // model, so observe each live player directly. Mirrors the pattern used by
  // the first-party omarchy media service.
  Instantiator {
    model: Mpris.players ? Mpris.players.values : []
    delegate: Connections {
      required property var modelData
      target: modelData
      function onIsPlayingChanged() { root.recalc() }
    }
  }

  Process {
    id: toggleProcess
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastError = String(text || "").trim().slice(0, 512) || root.lastError
      }
    }
    onExited: function(exitCode) {
      root.toggleInFlight = false
      root.lastToggle = new Date()
      if (Number(exitCode) !== 0 && !root.lastError) {
        root.lastError = "toggle failed with exit code " + exitCode
      }
      if (root.hasPendingToggle) Qt.callLater(root.flushToggle)
    }
  }

  visible: false
  width: 0
  height: 0

  IpcHandler {
    target: "io-github-pxllbt-media-idle-inhibit"

    function status(): string {
      return JSON.stringify(root.diagnosticStatus())
    }
  }
}