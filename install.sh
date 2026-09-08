#!/bin/bash
set -euo pipefail

PLUGIN_ID="io.github.pxllbt.media-idle-inhibit"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

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
  if [ ! -f "$SHELL_JSON" ]; then
    echo "Error: $SHELL_JSON not found" >&2
    exit 1
  fi
  python3 - "$PLUGIN_ID" "$SHELL_JSON" <<'PY'
import json
import sys

plugin_id, path = sys.argv[1], sys.argv[2]

with open(path) as f:
    data = json.load(f)

bar = data.setdefault("bar", {})
layout = bar.setdefault("layout", {})
plugins = data.setdefault("plugins", [])

entry = {"id": plugin_id}
added_plugin = False
for p in plugins:
    if isinstance(p, dict) and p.get("id") == plugin_id:
        break
else:
    plugins.append(dict(entry))
    added_plugin = True

section = layout.setdefault("right", [])
added_widget = False
for w in section:
    if isinstance(w, dict) and w.get("id") == plugin_id:
        break
else:
    # Place after omarchy.tray to mirror the registry's default anchor; fall
    # back to appending if the tray widget is not present.
    for i, w in enumerate(section):
        if isinstance(w, dict) and w.get("id") == "omarchy.tray":
            section.insert(i + 1, dict(entry))
            break
    else:
        section.append(dict(entry))
    added_widget = True

if added_plugin or added_widget:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Enabled %s in %s" % (plugin_id, path))
else:
    print("%s already enabled in %s" % (plugin_id, path))
PY
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
    "$PLUGIN_DIR/validate.sh" || echo "Warning: validation script reported issues" >&2
  fi
  restart_shell
  echo "Installation complete."
}

main "$@"