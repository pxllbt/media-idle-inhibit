# io.github.pixllbeat.media-idle-inhibit

<https://github.com/pxllbt/media-idle-inhibit>

Suppresses the screensaver and session lock while media is actively playing, using
D-Bus MPRIS and `omarchy-toggle-idle`. When a known player starts playback it runs
`omarchy-toggle-idle on`; when all known players stop it runs `omarchy-toggle-idle off`.

## Features

- Signal-based MPRIS detection via Quickshell's `Quickshell.Services.Mpris` (no polling)
- Automatic toggle only for recognized players; other MPRIS clients are ignored
- Optional bar widget: a `MEDIA` pill with icon + player name while active
- IPC diagnostics via `qs ipc call io-github-pixllbeat-media-idle-inhibit status`
- Stdout/stderr capture and error state surfaced through the bar widget tooltip

## Supported players

- mpv, vlc, celluloid, gnome-mpv, totem, kodi
- firefox, chrome, chromium, brave-browser
- spotify
- any other player exposing the standard `org.mpris.MediaPlayer2.*` interface

## Install

```bash
cd /path/to/media-idle-inhibit
./install.sh
```

`install.sh` copies the plugin to
`~/.config/omarchy/plugins/io.github.pixllbeat.media-idle-inhibit`, validates the
manifest, enables it in `~/.config/omarchy/shell.json`, and restarts the shell.

### Breaking change

If a previous `pixllbeat.media-idle-inhibit` install exists, uninstall it first: it
is not auto-migrated. The new plugin id is `io.github.pixllbeat.media-idle-inhibit`.

## Uninstall

```bash
~/.config/omarchy/plugins/io.github.pixllbeat.media-idle-inhibit/uninstall.sh
```

## Manual install

```bash
cp -r /path/to/media-idle-inhibit ~/.config/omarchy/plugins/io.github.pixllbeat.media-idle-inhibit
```

Add the plugin to `~/.config/omarchy/shell.json`:

```json
{
  "plugins": [
    { "id": "io.github.pixllbeat.media-idle-inhibit" }
  ]
}
```

Then restart the shell:

```bash
omarchy restart shell
```

## Debugging

Query the service diagnostic status over IPC:

```bash
qs ipc call io-github-pixllbeat-media-idle-inhibit status
```

Returns a JSON object with `mediaPlaying`, `activePlayerName`, `lastToggle`,
`lastError`, and `toggleInFlight`.

## Known limitations

- Only one playing player is tracked at a time (the first known player found).
- The idle toggle is best-effort: if `omarchy-toggle-idle` exits non-zero, the error
  is recorded in `lastError` and surfaced via the bar widget tooltip, with no retry.
- The bar widget reflects the service state over IPC; it does not drive toggling itself.

## Validation

Run the bundled validator:

```bash
~/.config/omarchy/plugins/io.github.pixllbeat.media-idle-inhibit/validate.sh
```

Manual smoke test:
1. Start video playback in mpv, vlc, or firefox.
2. Wait >150s without input.
3. Confirm screensaver/lock does not trigger.
4. Stop/close media.
5. Wait >150s without input.
6. Confirm screensaver/lock works normally.

## License

MIT
