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
  property date lastToggle: new Date(0)
  property bool toggleInFlight: false

  readonly property var knownPlayerEntries: [
    "mpv", "vlc", "celluloid", "gnome-mpv", "totem", "kodi",
    "firefox", "chrome", "chromium", "brave-browser", "spotify"
  ]

  function isKnownPlayer(player) {
    if (!player) return false
    const entry = String(player.desktopEntry || "").toLowerCase()
    const identity = String(player.identity || "").toLowerCase()
    const bus = String(player.dbusName || "")
    if (bus.indexOf("org.mpris.MediaPlayer2") === 0) return true
    for (let i = 0; i < knownPlayerEntries.length; i++) {
      if (entry === knownPlayerEntries[i] || identity === knownPlayerEntries[i]) return true
    }
    return false
  }

  function currentPlayingPlayer() {
    if (!Mpris.players) return null
    const players = Mpris.players.values || []
    for (let i = 0; i < players.length; i++) {
      const p = players[i]
      if (p && p.isPlaying === true && isKnownPlayer(p)) return p
    }
    return null
  }

  function applyToggle(enable) {
    if (root.toggleInFlight) return
    root.toggleInFlight = true
    root.lastError = ""
    toggleProcess.command = ["omarchy-toggle-idle", enable ? "on" : "off"]
    toggleProcess.running = true
  }

  function recalc() {
    const wasPlaying = root.mediaPlaying
    const player = root.currentPlayingPlayer()
    const nowPlaying = player !== null
    const nextName = player ? String(player.desktopEntry || player.identity || "") : ""

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
      lastError: root.lastError,
      toggleInFlight: root.toggleInFlight
    }
  }

  Component.onCompleted: root.recalc()

  Connections {
    target: Mpris.players
    function onRowsInserted() { root.recalc() }
    function onRowsRemoved() { root.recalc() }
    function onModelReset() { root.recalc() }
    function onDataChanged() { root.recalc() }
  }

  Process {
    id: toggleProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastToggle = new Date()
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastError = String(text || "").trim().slice(0, 512)
        root.toggleInFlight = false
      }
    }
    onExited: function(exitCode) {
      root.toggleInFlight = false
      if (Number(exitCode) !== 0 && !root.lastError) {
        root.lastError = "omarchy-toggle-idle exited with code " + exitCode
      }
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
