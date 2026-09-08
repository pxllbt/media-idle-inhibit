#!/bin/bash
set -euo pipefail

PLUGIN_ID="io.github.pxllbt.media-idle-inhibit"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$PLUGIN_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# validate.sh can run from the repo checkout (before install) or from the
# installed plugin directory. Resolve which folder we actually validate.
if [ -f "$SCRIPT_DIR/manifest.json" ] && [ "$SCRIPT_DIR" != "$PLUGIN_DIR" ]; then
  TARGET_DIR="$SCRIPT_DIR"
fi

check_files() {
  echo "== Checking plugin structure =="
  for f in manifest.json Service.qml BarWidget.qml install.sh uninstall.sh validate.sh README.md LICENSE .gitignore; do
    [ -f "$TARGET_DIR/$f" ] || fail "Missing $f"
  done
  pass "All required files present"
}

check_manifest() {
  echo "== Validating manifest =="
  python3 -c "import json; json.load(open('$TARGET_DIR/manifest.json'))" || fail "manifest.json is not valid JSON"
  local mid
  mid=$(python3 -c "import json; print(json.load(open('$TARGET_DIR/manifest.json'))['id'])")
  [ "$mid" = "$PLUGIN_ID" ] || fail "manifest id mismatch: $mid"
  local ver
  ver=$(python3 -c "import json; print(json.load(open('$TARGET_DIR/manifest.json')).get('version',''))")
  [ "$ver" != "" ] || fail "manifest missing version"
  pass "manifest.json valid"
}

check_qml_imports() {
  echo "== Checking QML imports =="
  grep -q "Quickshell.Services.Mpris" "$TARGET_DIR/Service.qml" || fail "Service.qml missing Mpris import"
  grep -q "Quickshell.Io" "$TARGET_DIR/Service.qml" || fail "Service.qml missing Io import"
  grep -q "IpcHandler" "$TARGET_DIR/Service.qml" || fail "Service.qml missing IpcHandler"
  grep -q "Process" "$TARGET_DIR/Service.qml" || fail "Service.qml missing Process"
  grep -q "StdioCollector" "$TARGET_DIR/Service.qml" || fail "Service.qml missing StdioCollector"
  grep -q "qs.Ui" "$TARGET_DIR/BarWidget.qml" || fail "BarWidget.qml missing qs.Ui import"
  grep -q "PillSurface" "$TARGET_DIR/BarWidget.qml" || fail "BarWidget.qml missing PillSurface"
  grep -q "IconText" "$TARGET_DIR/BarWidget.qml" || fail "BarWidget.qml missing IconText"
  pass "QML imports present"
}

check_observation() {
  echo "== Verifying signal-based playback detection =="
  grep -q "Instantiator" "$TARGET_DIR/Service.qml" || fail "Service.qml missing Instantiator for per-player change tracking"
  grep -q "onIsPlayingChanged" "$TARGET_DIR/Service.qml" || fail "Service.qml missing onIsPlayingChanged wiring"
  grep -q "Connections" "$TARGET_DIR/Service.qml" || fail "Service.qml missing Connections"
  if grep -q "Timer" "$TARGET_DIR/Service.qml"; then
    fail "Service.qml still contains Timer-based polling"
  fi
  pass "Signal-based playback detection verified"
}

check_ownership() {
  echo "== Verifying stay-awake ownership marker =="
  grep -q "stay-awake.media" "$TARGET_DIR/Service.qml" || fail "Service.qml missing ownership marker handling"
  pass "Owner marker present"
}

check_ipc_target() {
  echo "== Checking IPC target naming =="
  grep -q 'target: "io-github-pxllbt-media-idle-inhibit"' "$TARGET_DIR/Service.qml" || fail "IPC target name mismatch"
  pass "IPC target name matches plugin id pattern"
}

check_runtime_prereqs() {
  echo "== Checking runtime prerequisites =="
  if command -v omarchy-toggle-idle >/dev/null 2>&1; then
    local result
    result=$(omarchy-toggle-idle status 2>/dev/null) || result=""
    if [ -n "$result" ]; then
      pass "omarchy-toggle-idle available and responding"
    else
      warn "omarchy-toggle-idle present but status probe failed (fallback file mode applies)"
    fi
  else
    warn "omarchy-toggle-idle not found; the service falls back to writing the indicator file directly"
  fi
}

main() {
  echo "Validating $PLUGIN_ID (validated folder: $TARGET_DIR)"
  check_files
  check_manifest
  check_qml_imports
  check_observation
  check_ownership
  check_ipc_target
  check_runtime_prereqs
  echo ""
  echo "All validation checks passed."
}

main "$@"