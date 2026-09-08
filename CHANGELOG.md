# Changelog

All notable changes to this project are documented in this file.

## [1.2.0] - 2026-09-08

### Fixed
- Play/pause transitions are now detected reliably: the service watches each
  live player's `isPlaying` signal via an `Instantiator`, fixing missed toggles
  that could leave idle inhibited after playback stopped (or uninhibited while
  it played). Model signals alone do not fire on play/pause flips.
- Removing the inert "known player" whitelist. Its D-Bus name check always
  matched every player, so any MPRIS client was already treated as media. The
  plugin now deliberately treats any playing player as media.
- Stopping media no longer removes a stay-awake set manually by the user. An
  ownership marker guards releases, mirroring the `idle-owner` pattern of
  Omarchy's own `omarchy-update-stay-awake`.
- Rapid play/pause changes no longer drop toggle requests: a pending-state queue
  ensures the last requested state always wins.
- Startup self-heals stale owner markers left over from a crash or restart.

### Added
- Fallback mode that writes the idle indicator file directly when
  `omarchy-toggle-idle` is not installed, for broader Omarchy compatibility.
- `lastToggleValue` ("on"/"off") exposed over IPC for diagnostics.

### Changed
- `install.sh` now enables the plugin correctly: it registers it in
  `~/.config/omarchy/shell.json` both as a plugin and as a right-section bar
  widget (the previous version only touched the plugins list, so the widget
  never appeared on the bar).
- `uninstall.sh` removes the plugin from shell.json before deleting files.
- `validate.sh` checks the new signal-based observation and ownership marker,
  validates manifest/folder structure, and no longer flips the live idle state
  during validation.

## [1.1.0] - 2026-09-08

### Changed
- Plugin id renamed to `io.github.pxllbt.media-idle-inhibit`.

## [1.0.0] - 2026-09-08

### Added
- Initial public release with signal-based MPRIS detection and bar widget.