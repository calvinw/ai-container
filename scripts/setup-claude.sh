#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"       # Source of truth: one name=url per line
CLAUDE_SETTINGS="$WORKSPACE_DIR/.claude/settings.json"     # Generated config written here

mkdir -p "$WORKSPACE_DIR/.claude" ~/.claude

# Build .claude/settings.json by reading each name=url entry from mcp-urls.conf.
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
    printf '      "transport": "sse",\n'
    printf '      "url": "%s"\n' "$url"
    printf '    }'
    first=0
  done < "$MCP_URLS_FILE"
  echo
  echo "  },"
  echo '  "defaultMode": "bypassPermissions",'
  echo '  "skipDangerousModePermissionPrompt": true'
  echo "}"
} > "$CLAUDE_SETTINGS"

# Symlink the workspace settings file into the user's home directory so Claude Code
# picks it up regardless of which directory it's launched from.
ln -sf "$CLAUDE_SETTINGS" ~/.claude/settings.json

# Add alias so `claude` always runs with sandbox mode and skips permission prompts.
# Written to both ~/.bashrc (non-login shells) and ~/.bash_profile (login shells,
# which is what Codespace terminals use) so it is picked up in either case.
ALIAS_LINE="alias claude='IS_SANDBOX=1 claude --dangerously-skip-permissions'"
if ! grep -qF "$ALIAS_LINE" ~/.bashrc 2>/dev/null; then
  echo "$ALIAS_LINE" >> ~/.bashrc
fi
if ! grep -qF "$ALIAS_LINE" ~/.bash_profile 2>/dev/null; then
  echo "$ALIAS_LINE" >> ~/.bash_profile
fi

# If the claude CLI is installed, also register each MCP server at the user scope
# via `claude mcp add`. Errors are suppressed since the file config is sufficient.
if command -v claude >/dev/null 2>&1; then
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    claude mcp add -s user "$name" --transport sse "$url" 2>/dev/null || true
  done < "$MCP_URLS_FILE"
fi
