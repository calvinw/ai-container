#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"           # Source of truth: one name=url per line
OPENCODE_CONFIG="$WORKSPACE_DIR/.opencode/opencode.json"       # Generated config written here (gitignored)

mkdir -p "$WORKSPACE_DIR/.opencode" ~/.config/opencode

# Build .opencode/opencode.json by reading each name=url entry from mcp-urls.conf.
# Lines starting with # are skipped. OpenCode uses type "remote" with an explicit enabled flag
# for SSE-based MCP servers (different field names from Claude/Gemini/Copilot).
{
  echo "{"
  echo '  "$schema": "https://opencode.ai/config.json",'
  echo '  "mcp": {'
  first=1
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    if [ $first -eq 0 ]; then
      echo ","
    fi
    printf '    "%s": {\n' "$name"
    printf '      "type": "remote",\n'
    printf '      "url": "%s",\n' "$url"
    printf '      "enabled": true\n'
    printf '    }'
    first=0
  done < "$MCP_URLS_FILE"
  echo
  echo "  }"
  echo "}"
} > "$OPENCODE_CONFIG"

# Symlink the generated config into the user-level OpenCode config directory so OpenCode
# finds it regardless of which directory it's launched from.
ln -sf "$OPENCODE_CONFIG" ~/.config/opencode/opencode.json
