#!/bin/bash
# sync-from-upstream.sh — pull latest agentic tool files from calvinw/ai-agentic-tools
set -e

UPSTREAM="calvinw/ai-agentic-tools"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install from https://cli.github.com" >&2
  exit 1
fi

fetch() {
  local remote_path="$1"
  local local_path="$WORKSPACE_DIR/$2"
  mkdir -p "$(dirname "$local_path")"
  gh api "repos/$UPSTREAM/contents/$remote_path" --jq '.content' | base64 -d > "$local_path"
  echo "  synced $2"
}

echo "Syncing from $UPSTREAM..."

# devcontainer
fetch ".devcontainer/devcontainer.json"  ".devcontainer/devcontainer.json"
fetch ".devcontainer/post-create.sh"     ".devcontainer/post-create.sh"

# configs
fetch "configs/mcp-servers.conf"  "configs/mcp-servers.conf"

# tool configs
fetch ".mcp.json"               ".mcp.json"
fetch ".claude/settings.json"   ".claude/settings.json"
fetch ".crush.json"             ".crush.json"
fetch ".codex/config.toml"      ".codex/config.toml"
fetch ".opencode/opencode.json" ".opencode/opencode.json"
fetch ".gemini/settings.json"   ".gemini/settings.json"
fetch "Makefile"                "Makefile"

# permissions
fetch "permissions/claude.sh"    "permissions/claude.sh"
fetch "permissions/codex.sh"     "permissions/codex.sh"
fetch "permissions/copilot.sh"   "permissions/copilot.sh"
fetch "permissions/crush.sh"     "permissions/crush.sh"
fetch "permissions/opencode.sh"  "permissions/opencode.sh"

# scripts (including this script itself so it self-updates)
fetch "scripts/lib-mcp-parse.sh"          "scripts/lib-mcp-parse.sh"
fetch "scripts/setup-env.sh"              "scripts/setup-env.sh"
fetch "scripts/install-mcps.sh"           "scripts/install-mcps.sh"
fetch "scripts/uninstall-mcps.sh"         "scripts/uninstall-mcps.sh"
fetch "scripts/install-claude-mcp.sh"     "scripts/install-claude-mcp.sh"
fetch "scripts/uninstall-claude-mcp.sh"   "scripts/uninstall-claude-mcp.sh"
fetch "scripts/install-opencode-mcp.sh"   "scripts/install-opencode-mcp.sh"
fetch "scripts/uninstall-opencode-mcp.sh" "scripts/uninstall-opencode-mcp.sh"
fetch "scripts/install-copilot-mcp.sh"    "scripts/install-copilot-mcp.sh"
fetch "scripts/uninstall-copilot-mcp.sh"  "scripts/uninstall-copilot-mcp.sh"
fetch "scripts/install-crush-mcp.sh"      "scripts/install-crush-mcp.sh"
fetch "scripts/uninstall-crush-mcp.sh"    "scripts/uninstall-crush-mcp.sh"
fetch "scripts/install-gemini-mcp.sh"     "scripts/install-gemini-mcp.sh"
fetch "scripts/uninstall-gemini-mcp.sh"   "scripts/uninstall-gemini-mcp.sh"
fetch "scripts/install-codex-mcp.sh"      "scripts/install-codex-mcp.sh"
fetch "scripts/uninstall-codex-mcp.sh"    "scripts/uninstall-codex-mcp.sh"
fetch "scripts/install-datascience.sh"    "scripts/install-datascience.sh"
fetch "scripts/install-dolt.sh"           "scripts/install-dolt.sh"
fetch "scripts/install_upterm.sh"         "scripts/install_upterm.sh"
fetch "scripts/setup-skills.sh"           "scripts/setup-skills.sh"
fetch "scripts/sync-skills.sh"            "scripts/sync-skills.sh"
fetch "scripts/unsync-skills.sh"          "scripts/unsync-skills.sh"
fetch "scripts/sync-from-upstream.sh"     "scripts/sync-from-upstream.sh"

# make scripts executable
chmod +x "$WORKSPACE_DIR/.devcontainer/post-create.sh"
chmod +x "$WORKSPACE_DIR/permissions"/*.sh
chmod +x "$WORKSPACE_DIR/scripts"/*.sh

echo ""
echo "Done. Run 'git diff' to review changes before committing."
