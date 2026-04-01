#!/bin/bash
set -e

OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"
BACKUP="${OPENCODE_CONFIG}.bak"

# Inject "allow" for all permissions into the config, saving a backup first.
cp "$OPENCODE_CONFIG" "$BACKUP"
jq '. + {"permission": {"read": "allow", "write": "allow", "execute": "allow"}}' \
  "$BACKUP" > "$OPENCODE_CONFIG"

# Restore the original config when this script exits (normally or on error).
trap 'cp "$BACKUP" "$OPENCODE_CONFIG"; rm -f "$BACKUP"' EXIT

opencode
