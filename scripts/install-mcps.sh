#!/bin/bash
set -e

# install-mcps.sh — installs MCPs from configs/mcp-servers.conf into each
# tool's home directory config. Idempotent: safe to re-run, existing entries
# are replaced with current values.
#
# Conf file resolution (first match wins):
#   1. $WORKSPACE_DIR/configs/mcp-servers.conf  (workspace override)
#   2. /usr/local/lib/ai-tools/configs/mcp-servers.conf  (baked into image)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

if [ -f "$WORKSPACE_DIR/configs/mcp-servers.conf" ]; then
  MCP_CONF_FILE="$WORKSPACE_DIR/configs/mcp-servers.conf"
else
  MCP_CONF_FILE="/usr/local/lib/ai-tools/configs/mcp-servers.conf"
fi

. "$SCRIPT_DIR/lib-mcp-parse.sh"
parse_mcp_conf "$MCP_CONF_FILE"

if [ ${#MCP_NAMES[@]} -eq 0 ]; then
  echo "No MCPs configured in $MCP_CONF_FILE"
  exit 0
fi

echo "Installing ${#MCP_NAMES[@]} MCP(s) from $MCP_CONF_FILE"

# ── Claude ────────────────────────────────────────────────────────────────────
# Writes to ~/.claude/ (user scope) via the claude CLI.
# Removes existing entry first so re-runs update rather than error.
if command -v claude >/dev/null 2>&1; then
  echo "=== Claude ==="
  for i in "${!MCP_NAMES[@]}"; do
    name="${MCP_NAMES[$i]}"
    url="${MCP_URLS[$i]}"
    transport="${MCP_TRANSPORTS[$i]}"
    headers="${MCP_HEADERS[$i]}"
    claude mcp remove -s user "$name" 2>/dev/null || true
    args=(-s user "$name" --transport "$transport" "$url")
    if [[ -n "$headers" ]]; then
      IFS='|' read -ra hfields <<< "$headers"
      for hfield in "${hfields[@]}"; do
        args+=(--header "${hfield%%:*}: ${hfield#*:}")
      done
    fi
    claude mcp add "${args[@]}"
  done
  echo "Claude: done"
else
  echo "Claude: not found, skipping"
fi

# ── OpenCode ──────────────────────────────────────────────────────────────────
# Writes to ~/.config/opencode/opencode.json
# Uses type "remote" for both SSE and HTTP; oauth:false suppresses OAuth
# discovery when API key headers are present.
echo "=== OpenCode ==="
mkdir -p ~/.config/opencode
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
[ -f "$OPENCODE_CONFIG" ] || echo '{}' > "$OPENCODE_CONFIG"
python3 - "$OPENCODE_CONFIG" "${#MCP_NAMES[@]}" \
  "${MCP_NAMES[@]}" "${MCP_URLS[@]}" "${MCP_TRANSPORTS[@]}" "${MCP_HEADERS[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
count = int(sys.argv[2])
names       = sys.argv[3:3+count]
urls        = sys.argv[3+count:3+2*count]
transports  = sys.argv[3+2*count:3+3*count]
headers_raw = sys.argv[3+3*count:3+4*count]
with open(path) as f:
    config = json.load(f)
servers = config.setdefault("mcp", {})
for i in range(count):
    obj = {"type": "remote", "url": urls[i], "enabled": True}
    if headers_raw[i]:
        obj["oauth"] = False
        obj["headers"] = {h.partition(':')[0]: h.partition(':')[2]
                          for h in headers_raw[i].split('|')}
    servers[names[i]] = obj
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
echo "OpenCode: done"

# ── Gemini ────────────────────────────────────────────────────────────────────
# Writes to ~/.gemini/settings.json
echo "=== Gemini ==="
mkdir -p ~/.gemini
GEMINI_CONFIG="$HOME/.gemini/settings.json"
[ -f "$GEMINI_CONFIG" ] || echo '{}' > "$GEMINI_CONFIG"
python3 - "$GEMINI_CONFIG" "${#MCP_NAMES[@]}" \
  "${MCP_NAMES[@]}" "${MCP_URLS[@]}" "${MCP_TRANSPORTS[@]}" "${MCP_HEADERS[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
count = int(sys.argv[2])
names       = sys.argv[3:3+count]
urls        = sys.argv[3+count:3+2*count]
transports  = sys.argv[3+2*count:3+3*count]
headers_raw = sys.argv[3+3*count:3+4*count]
with open(path) as f:
    config = json.load(f)
servers = config.setdefault("mcpServers", {})
for i in range(count):
    if transports[i] == 'sse':
        servers[names[i]] = {"type": "sse", "url": urls[i]}
    else:
        obj = {"type": "http", "url": urls[i]}
        if headers_raw[i]:
            obj["headers"] = {h.partition(':')[0]: h.partition(':')[2]
                              for h in headers_raw[i].split('|')}
        servers[names[i]] = obj
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
echo "Gemini: done"

# ── Crush ─────────────────────────────────────────────────────────────────────
# Writes to ~/.config/crush/crush.json
echo "=== Crush ==="
mkdir -p ~/.config/crush
CRUSH_CONFIG="$HOME/.config/crush/crush.json"
[ -f "$CRUSH_CONFIG" ] || echo '{}' > "$CRUSH_CONFIG"
python3 - "$CRUSH_CONFIG" "${#MCP_NAMES[@]}" \
  "${MCP_NAMES[@]}" "${MCP_URLS[@]}" "${MCP_TRANSPORTS[@]}" "${MCP_HEADERS[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
count = int(sys.argv[2])
names       = sys.argv[3:3+count]
urls        = sys.argv[3+count:3+2*count]
transports  = sys.argv[3+2*count:3+3*count]
headers_raw = sys.argv[3+3*count:3+4*count]
with open(path) as f:
    config = json.load(f)
servers = config.setdefault("mcp", {})
for i in range(count):
    if transports[i] == 'sse':
        servers[names[i]] = {"type": "sse", "url": urls[i]}
    else:
        obj = {"type": "http", "url": urls[i]}
        if headers_raw[i]:
            obj["headers"] = {h.partition(':')[0]: h.partition(':')[2]
                              for h in headers_raw[i].split('|')}
        servers[names[i]] = obj
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
echo "Crush: done"

# ── Copilot ───────────────────────────────────────────────────────────────────
# Writes to ~/.copilot/mcp-config.json
echo "=== Copilot ==="
mkdir -p ~/.copilot
COPILOT_CONFIG="$HOME/.copilot/mcp-config.json"
[ -f "$COPILOT_CONFIG" ] || echo '{}' > "$COPILOT_CONFIG"
python3 - "$COPILOT_CONFIG" "${#MCP_NAMES[@]}" \
  "${MCP_NAMES[@]}" "${MCP_URLS[@]}" "${MCP_TRANSPORTS[@]}" "${MCP_HEADERS[@]}" <<'EOF'
import json, sys
path = sys.argv[1]
count = int(sys.argv[2])
names       = sys.argv[3:3+count]
urls        = sys.argv[3+count:3+2*count]
transports  = sys.argv[3+2*count:3+3*count]
headers_raw = sys.argv[3+3*count:3+4*count]
with open(path) as f:
    config = json.load(f)
servers = config.setdefault("mcpServers", {})
for i in range(count):
    if transports[i] == 'sse':
        servers[names[i]] = {"type": "sse", "url": urls[i]}
    else:
        obj = {"type": "http", "url": urls[i]}
        if headers_raw[i]:
            obj["headers"] = {h.partition(':')[0]: h.partition(':')[2]
                              for h in headers_raw[i].split('|')}
        servers[names[i]] = obj
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF
echo "Copilot: done"

# ── Codex ─────────────────────────────────────────────────────────────────────
# Writes to ~/.codex/config.toml via supergateway (SSE/HTTP bridge).
# Removes existing sections first so re-runs update rather than skip.
# Skipped if supergateway is not installed.
echo "=== Codex ==="
CODEX_MCP_BRIDGE_BIN="$(command -v supergateway || true)"
if [ -n "$CODEX_MCP_BRIDGE_BIN" ]; then
  mkdir -p ~/.codex
  CODEX_CONFIG="$HOME/.codex/config.toml"
  [ -f "$CODEX_CONFIG" ] || touch "$CODEX_CONFIG"
  python3 - "$CODEX_CONFIG" "$CODEX_MCP_BRIDGE_BIN" "${#MCP_NAMES[@]}" \
    "${MCP_NAMES[@]}" "${MCP_URLS[@]}" "${MCP_TRANSPORTS[@]}" "${MCP_HEADERS[@]}" <<'EOF'
import sys, re
path = sys.argv[1]
bridge = sys.argv[2]
count = int(sys.argv[3])
names       = sys.argv[4:4+count]
urls        = sys.argv[4+count:4+2*count]
transports  = sys.argv[4+2*count:4+3*count]
headers_raw = sys.argv[4+3*count:4+4*count]
with open(path) as f:
    lines = f.readlines()
# Remove any existing sections for these names
names_set = set(names)
result = []
skip = False
for line in lines:
    m = re.match(r'^\[mcp_servers\.(?:"([^"]+)"|(\S+))\]', line)
    if m and (m.group(1) or m.group(2)) in names_set:
        skip = True
        continue
    if skip and re.match(r'^\[', line):
        skip = False
    if not skip:
        result.append(line)
while result and result[-1].strip() == "":
    result.pop()
content = "".join(result)
# Append updated entries
for i in range(count):
    name = names[i]
    section = f'[mcp_servers.{name}]'
    if transports[i] == 'sse':
        args = ["--sse", urls[i], "--logLevel", "none"]
    else:
        args = ["--streamableHttp", urls[i]]
        if headers_raw[i]:
            for h in headers_raw[i].split('|'):
                k, _, v = h.partition(':')
                args += ["--header", f"{k}: {v}"]
        args += ["--logLevel", "none"]
    args_str = '[' + ', '.join(f'"{a}"' for a in args) + ']'
    content = content.rstrip("\n") + f'\n\n{section}\ncommand = "{bridge}"\nargs = {args_str}\n'
with open(path, "w") as f:
    f.write(content)
EOF
  echo "Codex: done"
else
  echo "Codex: supergateway not found, skipping"
fi
