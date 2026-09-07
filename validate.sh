#!/bin/bash
set -euo pipefail

PLUGIN_ID="io.github.pxllbt.media-idle-inhibit"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
STATE_FILE="$HOME/.local/state/omarchy/indicators/stay-awake"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

check_files() {
  echo "== Checking plugin structure =="
  for f in manifest.json Service.qml BarWidget.qml install.sh uninstall.sh README.md LICENSE .gitignore; do
    [ -f "$PLUGIN_DIR/$f" ] || fail "Missing $f"
  done
  pass "All required files present"
}

check_manifest() {
  echo "== Validating manifest =="
  python3 -c "import json; json.load(open('$PLUGIN_DIR/manifest.json'))" || fail "manifest.json is not valid JSON"
  local mid
  mid=$(python3 -c "import json; print(json.load(open('$PLUGIN_DIR/manifest.json'))['id'])")
  [ "$mid" = "$PLUGIN_ID" ] || fail "manifest id mismatch: $mid"
  local ver
  ver=$(python3 -c "import json; print(json.load(open('$PLUGIN_DIR/manifest.json')).get('version',''))")
  [ "$ver" != "" ] || fail "manifest missing version"
  pass "manifest.json valid"
}

check_qml_syntax() {
  echo "== Checking QML imports =="
  grep -q "Quickshell.Services.Mpris" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing Mpris import"
  grep -q "Quickshell.Io" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing Io import"
  grep -q "IpcHandler" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing IpcHandler"
  grep -q "Process" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing Process"
  grep -q "StdioCollector" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing StdioCollector"
  grep -q "qs.Ui" "$PLUGIN_DIR/BarWidget.qml" || fail "BarWidget.qml missing qs.Ui import"
  grep -q "PillSurface" "$PLUGIN_DIR/BarWidget.qml" || fail "BarWidget.qml missing PillSurface"
  grep -q "IconText" "$PLUGIN_DIR/BarWidget.qml" || fail "BarWidget.qml missing IconText"
  pass "QML syntax checks passed"
}

check_toggle_side_effects() {
  echo "== Checking omarchy-toggle-idle side effects =="
  local original_state=""
  if [ -f "$STATE_FILE" ]; then
    original_state="present"
  else
    original_state="absent"
  fi

  omarchy-toggle-idle on >/dev/null 2>&1 || fail "omarchy-toggle-idle on failed"
  [ -f "$STATE_FILE" ] || fail "State file not created after 'on'"
  pass "omarchy-toggle-idle on creates state file"

  omarchy-toggle-idle off >/dev/null 2>&1 || fail "omarchy-toggle-idle off failed"
  [ ! -f "$STATE_FILE" ] || fail "State file not removed after 'off'"
  pass "omarchy-toggle-idle off removes state file"

  if [ "$original_state" = "present" ]; then
    omarchy-toggle-idle on >/dev/null 2>&1 || true
  fi
}

check_ipc_target() {
  echo "== Checking IPC target naming =="
  grep -q 'target: "io-github-pxllbt-media-idle-inhibit"' "$PLUGIN_DIR/Service.qml" || fail "IPC target name mismatch"
  pass "IPC target name matches plugin id pattern"
}

check_no_polling() {
  echo "== Verifying signal-based design (no polling) =="
  if grep -q "Timer" "$PLUGIN_DIR/Service.qml"; then
    fail "Service.qml still contains Timer-based polling"
  fi
  grep -q "Connections" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing Connections"
  grep -q "onRowsInserted" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing model row tracking"
  pass "Signal-based design verified"
}

check_error_visibility() {
  echo "== Checking error visibility =="
  grep -q "lastError" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing lastError"
  grep -q "lastToggle" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing lastToggle"
  grep -q "toggleInFlight" "$PLUGIN_DIR/Service.qml" || fail "Service.qml missing toggleInFlight"
  pass "Error visibility properties present"
}

main() {
  echo "Validating $PLUGIN_ID..."
  check_files
  check_manifest
  check_qml_syntax
  check_toggle_side_effects
  check_ipc_target
  check_no_polling
  check_error_visibility
  echo ""
  echo "All validation checks passed."
}

main "$@"
