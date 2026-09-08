# Media Idle Inhibit — Omarchy Plugin

Suppresses the screensaver and session lock while media is actively playing, using
D-Bus MPRIS and Omarchy's native idle indicator. When any player starts playback it
enables stay-awake; when all players stop it lets the system idle normally again.

Works out of the box on every Omarchy setup — no configuration required.

## Features

- Signal-based MPRIS detection via Quickshell's `Quickshell.Services.Mpris` (no polling)
- **Any** playing MPRIS player counts, including web players and apps that do not
  follow a fixed desktop-entry name
- Per-player `isPlaying` observation for instant play/pause detection
- Ownership-safe: stopping media never removes a stay-awake you enabled manually
- Optional bar widget: a `MEDIA` pill with icon + player name while idle is inhibited
- Self-healing: finds a stale idle-inhibit left by a crash and cleans it up on start
- IPC diagnostics via `qs ipc call io-github-pxllbt-media-idle-inhibit status`
- Fallback to directly writing the indicator file if `omarchy-toggle-idle` is absent

## Requirements

- Omarchy shell (Wayland / Hyprland) with Quickshell
- A D-Bus MPRIS player (mpv, VLC, Firefox, Chromium, Spotify, …) for detection
- `omarchy-toggle-idle` is used when present (it ships with Omarchy); the plugin
  falls back to writing the indicator file directly otherwise

## Install

Recommended — managed, updatable install:

```bash
omarchy plugin add https://github.com/pxllbt/media-idle-inhibit.git --enable --yes
omarchy plugin enable io.github.pxllbt.media-idle-inhibit --section right
```

This clones the plugin into `~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit`,
keeps a git checkout for updates (`omarchy plugin update io.github.pxllbt.media-idle-inhibit`),
enables it, and places the bar widget in the right section.

From a local checkout:

```bash
cd /path/to/media-idle-inhibit
./install.sh
```

`install.sh` copies the plugin to the plugins directory, validates the manifest,
registers it in `~/.config/omarchy/shell.json` (plugins list + right bar section),
runs `validate.sh`, and restarts the shell.

## Uninstall

```bash
~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit/uninstall.sh
```

## How it works

1. When a known MPRIS player starts playing, the service enables Omarchy's
   stay-awake indicator and records an ownership marker.
2. When the last playing player pauses or stops, it releases the indicator — but
   only if an ownership marker is present and no manual change happened after our
   own.
3. Play/pause changes are watched via each player's `isPlaying` signal, so
   transitions are applied immediately instead of being missed.
4. Rapid play/pause changes are queued, so the system always ends in the state
   requested last.

## Debugging

Query the service diagnostic status over IPC:

```bash
qs ipc call io-github-pxllbt-media-idle-inhibit status
```

Returns a JSON object with `mediaPlaying`, `activePlayerName`, `lastToggle`,
`lastToggleValue`, `lastError`, and `toggleInFlight`.

## Known limitations

- Idle is suppressed while any single player is playing; the most recently
  detected playing player is named in the widget.
- The idle toggle is best-effort: if the command exits non-zero, the error is
  recorded in `lastError` and surfaced via the bar widget tooltip.
- The bar widget reflects service state over IPC; it does not drive toggling itself.

## Validation

Run the bundled validator from a repo checkout or the installed plugin:

```bash
~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit/validate.sh
```

Manual smoke test: start playback in mpv/vlc/firefox → idle must not trigger;
stop media → idle works normally again.

## License

MIT