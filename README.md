# io.github.pxllbt.media-idle-inhibit

<https://github.com/pxllbt/media-idle-inhibit>

Suppresses the screensaver and session lock while media is actively playing, using
D-Bus MPRIS and `omarchy-toggle-idle`. When a known player starts playback it runs
`omarchy-toggle-idle on`; when all known players stop it runs `omarchy-toggle-idle off`.

## Features

- Signal-based MPRIS detection via Quickshell's `Quickshell.Services.Mpris` (no polling)
- Automatic toggle only for recognized players; other MPRIS clients are ignored
- Optional bar widget: a `MEDIA` pill with icon + player name while active
- IPC diagnostics via `qs ipc call io-github-pxllbt-media-idle-inhibit status`
- Stdout/stderr capture and error state surfaced through the bar widget tooltip

## Supported players

- mpv, vlc, celluloid, gnome-mpv, totem, kodi
- firefox, chrome, chromium, brave-browser
- spotify
- any other player exposing the standard `org.mpris.MediaPlayer2.*` interface

## Install

The plugin ships as a single folder of files — a whole, self-contained plugin.

**Quick install (zip, no git required):**

```bash
curl -fsSL https://github.com/pxllbt/media-idle-inhibit/archive/refs/tags/v1.1.0.zip -o media-idle-inhibit.zip
unzip media-idle-inhibit.zip
cd media-idle-inhibit-1.0.0
./install.sh
```

`install.sh` copies the plugin to
`~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit`, validates the
manifest, enables it in `~/.config/omarchy/shell.json`, runs `validate.sh`, and
restarts the shell.

**Git-managed install (enables automatic updates):**

```bash
omarchy plugin add https://github.com/pxllbt/media-idle-inhibit.git --enable
omarchy plugin update io.github.pxllbt.media-idle-inhibit
```

Installing via `omarchy plugin add` keeps a `.git` checkout, so
`omarchy plugin update` pulls new releases automatically.

**From a local checkout:**

```bash
cd /path/to/media-idle-inhibit
./install.sh
```

### Breaking change

If a previous `pixllbeat.media-idle-inhibit` install exists, uninstall it first:

```bash
~/.config/omarchy/plugins/pixllbeat.media-idle-inhibit/uninstall.sh
```

The new plugin id is `io.github.pxllbt.media-idle-inhibit`.

## Uninstall

```bash
~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit/uninstall.sh
```

## Manual install

```bash
cp -r /path/to/media-idle-inhibit ~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit
```

Add the plugin to `~/.config/omarchy/shell.json`:

```json
{
  "plugins": [
    { "id": "io.github.pxllbt.media-idle-inhibit" }
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
qs ipc call io-github-pxllbt-media-idle-inhibit status
```

Returns a JSON object with `mediaPlaying`, `activePlayerName`, `lastToggle`,
`lastError`, and `toggleInFlight`.

## Known limitations

- Only one playing player is tracked at a time (the first known player found).
- The idle toggle is best-effort: if `omarchy-toggle-idle` exits non-zero, the error
  is recorded in `lastError` and surfaced via the bar widget tooltip, with no retry.
- The bar widget reflects service state over IPC; it does not drive toggling itself.

## Validation

Run the bundled validator:

```bash
~/.config/omarchy/plugins/io.github.pxllbt.media-idle-inhibit/validate.sh
```

Manual smoke test: start playback in mpv/vlc/firefox → wait >150s → screensaver
must not trigger; stop media → wait → screensaver works normally.

## License

MIT
