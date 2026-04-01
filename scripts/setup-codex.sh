#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"               # One name=url per line
WORKSPACE_CODEX_DIR="$WORKSPACE_DIR/.codex"
CODEX_CONFIG="$WORKSPACE_CODEX_DIR/config.toml"                    # Generated config written here
CODEX_MCP_BRIDGE_DIR="$WORKSPACE_DIR/.codex-tools/supergateway"    # Local npm install of supergateway
CODEX_MCP_BRIDGE_BIN="$CODEX_MCP_BRIDGE_DIR/node_modules/.bin/supergateway"

# Helper: run apt-get with sudo if available, directly if already root, or fail gracefully.
run_apt() {
  if [ "$(id -u)" -eq 0 ]; then
    apt-get "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo apt-get "$@"
  else
    return 127
  fi
}

# Codex uses Bubblewrap (bwrap) to sandbox its tool execution on Linux.
# Install it if missing and apt-get is available (Debian/Ubuntu-based Codespaces).
if ! command -v bwrap >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  if run_apt update && run_apt install -y bubblewrap; then
    echo "Installed bubblewrap for Codex sandboxing."
  else
    echo "WARNING: Unable to install bubblewrap automatically. Continuing without it." >&2
  fi
fi

mkdir -p "$WORKSPACE_CODEX_DIR" ~/.codex

# Install supergateway — its binary path is written into the generated config below.
# Codex does not natively support SSE-based MCP servers, so supergateway acts as a bridge:
# it wraps an SSE endpoint and exposes it as a stdio subprocess that Codex can spawn.
if command -v npm >/dev/null 2>&1; then
  if [ ! -x "$CODEX_MCP_BRIDGE_BIN" ]; then
    mkdir -p "$CODEX_MCP_BRIDGE_DIR"
    if [ ! -f "$CODEX_MCP_BRIDGE_DIR/package.json" ]; then
      cat > "$CODEX_MCP_BRIDGE_DIR/package.json" <<'EOF'
{
  "name": "codex-mcp-bridge",
  "private": true,
  "version": "1.0.0",
  "dependencies": {
    "supergateway": "3.4.3"
  }
}
EOF
    fi
    npm install --prefix "$CODEX_MCP_BRIDGE_DIR" >/dev/null 2>&1
  fi
fi

# Remove any existing symlink or file at the target paths before generating.
rm -f "$CODEX_CONFIG" ~/.codex/config.toml

# Generate .codex/config.toml from the current workspace path and mcp-urls.conf.
{
  echo 'approvals_reviewer = "user"'
  echo 'profile = "codespace"'
  echo ''
  echo '[profiles.codespace]'
  echo 'sandbox_mode = "danger-full-access"'
  echo 'ask_for_approval = "never"'
  echo ''
  echo "[projects.\"$WORKSPACE_DIR\"]"
  echo 'trust_level = "trusted"'
  echo ''
  echo '[plugins."gmail@openai-curated"]'
  echo 'enabled = true'
  echo ''
  echo '[plugins."github@openai-curated"]'
  echo 'enabled = true'
  if [ -x "$CODEX_MCP_BRIDGE_BIN" ] && [ -f "$MCP_URLS_FILE" ]; then
    while IFS='=' read -r name url; do
      [ -z "$name" ] && continue
      case "$name" in \#*) continue ;; esac
      echo ''
      echo "[mcp_servers.$name]"
      echo "command = \"$CODEX_MCP_BRIDGE_BIN\""
      echo "args = [\"--sse\", \"$url\", \"--logLevel\", \"none\"]"
    done < "$MCP_URLS_FILE"
  fi
} > "$CODEX_CONFIG"

# Symlink the generated config into the user home dir so Codex finds it
# regardless of which directory it's launched from.
ln -sf "$CODEX_CONFIG" ~/.codex/config.toml

if [ -f ~/.codex/config.toml ]; then
  echo "Codex config generated: $CODEX_CONFIG"
  if grep -q 'profile = "codespace"' ~/.codex/config.toml && \
     grep -q 'sandbox_mode = "danger-full-access"' ~/.codex/config.toml && \
     grep -q 'ask_for_approval = "never"' ~/.codex/config.toml; then
    echo "Codex default profile verified: codespace (danger-full-access, ask_for_approval=never)"
  else
    echo "WARNING: Codex config found, but the expected codespace profile defaults were not detected."
  fi
else
  echo "WARNING: ~/.codex/config.toml was not created."
fi
