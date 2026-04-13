#!/bin/bash
set -e

# uninstall-mcps.sh — removes MCPs listed in configs/mcp-servers.conf from
# each tool's home directory config. Safe to re-run.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

if [ -f "$WORKSPACE_DIR/configs/mcp-servers.conf" ]; then
  MCP_CONF_FILE="$WORKSPACE_DIR/configs/mcp-servers.conf"
else
  MCP_CONF_FILE="/usr/local/lib/ai-tools/configs/mcp-servers.conf"
fi

. "$SCRIPT_DIR/lib-mcp-parse.sh"
parse_mcp_names_only "$MCP_CONF_FILE"

if [ ${#MCP_NAMES[@]} -eq 0 ]; then
  echo "No MCPs configured in $MCP_CONF_FILE"
  exit 0
fi

echo "Removing ${#MCP_NAMES[@]} MCP(s)"

# ── Claude ────────────────────────────────────────────────────────────────────
if command -v claude >/dev/null 2>&1; then
  echo "=== Claude ==="
  for name in "${MCP_NAMES[@]}"; do
    claude mcp remove -s user "$name" 2>/dev/null || true
  done
  echo "Claude: done"
else
  echo "Claude: not found, skipping"
fi

# ── OpenCode ──────────────────────────────────────────────────────────────────
echo "=== OpenCode ==="
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$OPENCODE_CONFIG" ]; then
  python3 - "$OPENCODE_CONFIG" "${MCP_NAMES[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
names = set(sys.argv[2:])
with open(path) as f:
    config = json.load(f)
for name in names:
    config.get("mcp", {}).pop(name, None)
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
  echo "OpenCode: done"
else
  echo "OpenCode: config not found, skipping"
fi

# ── Gemini ────────────────────────────────────────────────────────────────────
echo "=== Gemini ==="
GEMINI_CONFIG="$HOME/.gemini/settings.json"
if [ -f "$GEMINI_CONFIG" ]; then
  python3 - "$GEMINI_CONFIG" "${MCP_NAMES[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
names = set(sys.argv[2:])
with open(path) as f:
    config = json.load(f)
for name in names:
    config.get("mcpServers", {}).pop(name, None)
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
  echo "Gemini: done"
else
  echo "Gemini: config not found, skipping"
fi

# ── Crush ─────────────────────────────────────────────────────────────────────
echo "=== Crush ==="
CRUSH_CONFIG="$HOME/.config/crush/crush.json"
if [ -f "$CRUSH_CONFIG" ]; then
  python3 - "$CRUSH_CONFIG" "${MCP_NAMES[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
names = set(sys.argv[2:])
with open(path) as f:
    config = json.load(f)
for name in names:
    config.get("mcp", {}).pop(name, None)
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
  echo "Crush: done"
else
  echo "Crush: config not found, skipping"
fi

# ── Copilot ───────────────────────────────────────────────────────────────────
echo "=== Copilot ==="
COPILOT_CONFIG="$HOME/.copilot/mcp-config.json"
if [ -f "$COPILOT_CONFIG" ]; then
  python3 - "$COPILOT_CONFIG" "${MCP_NAMES[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
names = set(sys.argv[2:])
with open(path) as f:
    config = json.load(f)
for name in names:
    config.get("mcpServers", {}).pop(name, None)
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
  echo "Copilot: done"
else
  echo "Copilot: config not found, skipping"
fi

# ── Codex ─────────────────────────────────────────────────────────────────────
echo "=== Codex ==="
CODEX_CONFIG="$HOME/.codex/config.toml"
if [ -f "$CODEX_CONFIG" ]; then
  python3 - "$CODEX_CONFIG" "${MCP_NAMES[@]}" <<'EOF'
import sys, re
path = sys.argv[1]
names = set(sys.argv[2:])
with open(path) as f:
    lines = f.readlines()
result = []
skip = False
for line in lines:
    m = re.match(r'^\[mcp_servers\.(?:"([^"]+)"|(\S+))\]', line)
    if m and (m.group(1) or m.group(2)) in names:
        skip = True
        continue
    if skip and re.match(r'^\[', line):
        skip = False
    if not skip:
        result.append(line)
while result and result[-1].strip() == "":
    result.pop()
if result:
    result.append("\n")
with open(path, "w") as f:
    f.writelines(result)
EOF
  echo "Codex: done"
else
  echo "Codex: config not found, skipping"
fi
