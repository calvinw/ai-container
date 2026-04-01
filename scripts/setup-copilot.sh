#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"           # Source of truth: one name=url per line
COPILOT_CONFIG="$WORKSPACE_DIR/.copilot/mcp-config.json"       # Generated config written here (gitignored)

mkdir -p "$WORKSPACE_DIR/.copilot" ~/.copilot

# Build .copilot/mcp-config.json by reading each name=url entry from mcp-urls.conf.
# Lines starting with # are skipped. Copilot uses type "sse" for SSE-based MCP servers.
{
  echo "{"
  echo '  "mcpServers": {'
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
} > "$COPILOT_CONFIG"

# Symlink the generated config into the user-level Copilot config directory so Copilot
# finds it regardless of which directory it's launched from.
ln -sf "$COPILOT_CONFIG" ~/.copilot/mcp-config.json
