#!/bin/bash
# sync-from-upstream.sh — pull latest config files from calvinw/ai-agentic-tools
# Scripts and permissions are baked into the Docker image; only configs and
# devcontainer setup are synced here.
set -e

UPSTREAM="calvinw/ai-agentic-tools"
WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

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

# tool configs (project-level, non-MCP settings only)
fetch ".opencode/opencode.json" ".opencode/opencode.json"
fetch ".codex/config.toml"      ".codex/config.toml"

fetch "Makefile" "Makefile"

# make post-create executable
chmod +x "$WORKSPACE_DIR/.devcontainer/post-create.sh"

echo ""
echo "Done. Run 'git diff' to review changes before committing."
