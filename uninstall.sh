#!/bin/bash
set -euo pipefail

PLUGIN_ID="io.github.pixllbeat.media-idle-inhibit"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

disable_plugin() {
  if [ ! -f "$SHELL_JSON" ]; then
    echo "Warning: $SHELL_JSON not found" >&2
    return
  fi
  python3 -c "
import json
with open('$SHELL_JSON') as f:
    data = json.load(f)
plugins = data.get('plugins', [])
before = len(plugins)
data['plugins'] = [p for p in plugins if not (isinstance(p, dict) and p.get('id') == '$PLUGIN_ID')]
if len(data['plugins']) < before:
    with open('$SHELL_JSON', 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    print('Disabled $PLUGIN_ID in shell.json')
else:
    print('$PLUGIN_ID was not enabled')
" || echo "Warning: failed to update shell.json" >&2
}

remove_plugin() {
  if [ -d "$PLUGIN_DIR" ]; then
    rm -rf "$PLUGIN_DIR"
    echo "Removed $PLUGIN_DIR"
  else
    echo "Plugin directory $PLUGIN_DIR not found"
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
  echo "Uninstalling $PLUGIN_ID..."
  disable_plugin
  remove_plugin
  restart_shell
  echo "Uninstall complete."
}

main "$@"
