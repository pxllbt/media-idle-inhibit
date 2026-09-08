#!/bin/bash
set -euo pipefail

PLUGIN_ID="io.github.pxllbt.media-idle-inhibit"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

disable_plugin() {
  if [ ! -f "$SHELL_JSON" ]; then
    echo "Warning: $SHELL_JSON not found" >&2
    return
  fi
  python3 - "$PLUGIN_ID" "$SHELL_JSON" <<'PY'
import json
import sys

plugin_id, path = sys.argv[1], sys.argv[2]

with open(path) as f:
    data = json.load(f)

changed = False

plugins = data.get("plugins", [])
before = len(plugins)
data["plugins"] = [p for p in plugins if not (isinstance(p, dict) and p.get("id") == plugin_id)]
if len(data["plugins"]) < before:
    changed = True

layout = data.get("bar", {}).get("layout", {})
if isinstance(layout, dict):
    for section in layout.values():
        if not isinstance(section, list):
            continue
        before = len(section)
        pruned = [w for w in section if not (isinstance(w, dict) and w.get("id") == plugin_id)]
        section[:] = pruned
        if len(section) < before:
            changed = True

if changed:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Disabled %s in %s" % (plugin_id, path))
else:
    print("%s was not enabled" % plugin_id)
PY
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