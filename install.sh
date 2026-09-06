#!/bin/bash
set -euo pipefail

PLUGIN_ID="io.github.pixllbeat.media-idle-inhibit"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate_manifest() {
  if [ ! -f "$SCRIPT_DIR/manifest.json" ]; then
    echo "Error: manifest.json not found in $SCRIPT_DIR" >&2
    exit 1
  fi
  if ! python3 -c "import json; json.load(open('$SCRIPT_DIR/manifest.json'))" 2>/dev/null; then
    echo "Error: manifest.json is not valid JSON" >&2
    exit 1
  fi
  local plugin_id
  plugin_id=$(python3 -c "import json; print(json.load(open('$SCRIPT_DIR/manifest.json'))['id'])")
  if [ "$plugin_id" != "$PLUGIN_ID" ]; then
    echo "Error: manifest id '$plugin_id' does not match expected '$PLUGIN_ID'" >&2
    exit 1
  fi
  echo "Validated manifest.json"
}

enable_plugin() {
  local shell_json="$HOME/.config/omarchy/shell.json"
  if [ ! -f "$shell_json" ]; then
    echo "Error: $shell_json not found" >&2
    exit 1
  fi
  if ! python3 -c "
import json, sys
with open('$shell_json') as f:
    data = json.load(f)
plugins = data.get('plugins', [])
ids = [p.get('id') for p in plugins if isinstance(p, dict)]
if '$PLUGIN_ID' not in ids:
    plugins.append({'id': '$PLUGIN_ID'})
    data['plugins'] = plugins
    with open('$shell_json', 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    print('Enabled $PLUGIN_ID in shell.json')
else:
    print('$PLUGIN_ID already enabled')
" ; then
    echo "Error: failed to update shell.json" >&2
    exit 1
  fi
}

copy_plugin() {
  mkdir -p "$PLUGIN_DIR"
  if [ "$SCRIPT_DIR" = "$PLUGIN_DIR" ]; then
    echo "Source and destination are the same, skipping copy"
  else
    cp -r "$SCRIPT_DIR"/. "$PLUGIN_DIR/"
    echo "Copied plugin files to $PLUGIN_DIR"
  fi
}

restart_shell() {
  if command -v omarchy >/dev/null 2>&1; then
    omarchy restart shell || true
    echo "Requested shell restart"
  else
    echo "omarchy command not found, please restart shell manually" >&2
  fi
}

main() {
  echo "Installing $PLUGIN_ID..."
  validate_manifest
  copy_plugin
  enable_plugin
  if [ -x "$PLUGIN_DIR/validate.sh" ]; then
    "$PLUGIN_DIR/validate.sh" || warn "Validation script reported issues"
  fi
  restart_shell
  echo "Installation complete."
}

main "$@"
