#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"       # Source of truth: one name=url per line
GEMINI_SETTINGS="$WORKSPACE_DIR/.gemini/settings.json"     # Generated config written here

mkdir -p "$WORKSPACE_DIR/.gemini" ~/.gemini

# Build .gemini/settings.json by reading each name=url entry from mcp-urls.conf.
# Lines starting with # are skipped. The result is a JSON mcpServers block using SSE transport.
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
} > "$GEMINI_SETTINGS"

# Symlink the generated config into the user's home directory so Gemini finds it
# regardless of which directory it's launched from.
ln -sf "$GEMINI_SETTINGS" ~/.gemini/settings.json
