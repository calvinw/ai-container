#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"   # Source of truth: one name=url per line
CRUSH_CONFIG="$WORKSPACE_DIR/.crush.json"              # Generated config written here (gitignored)

mkdir -p ~/.config/crush

# Build .crush.json by reading each name=url entry from mcp-urls.conf.
# Lines starting with # are skipped. Crush uses type "sse" for SSE-based MCP servers.
{
  echo "{"
  echo '  "$schema": "https://charm.land/crush.json",'
  echo '  "mcp": {'
  first=1
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    if [ $first -eq 0 ]; then
      echo ","
    fi
    printf '    "%s": {\n' "$name"
    printf '      "type": "sse",\n'
    printf '      "url": "%s"\n' "$url"
    printf '    }'
    first=0
  done < "$MCP_URLS_FILE"
  echo
  echo "  }"
  echo "}"
} > "$CRUSH_CONFIG"

# Symlink the generated config into the user-level Crush config directory so Crush
# finds it regardless of which directory it's launched from.
ln -sf "$CRUSH_CONFIG" ~/.config/crush/crush.json
