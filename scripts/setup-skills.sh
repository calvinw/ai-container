#!/bin/bash
set -euo pipefail

# Creates the .skillshare directory structure, installs the skillshare CLI,
# and drops in a sample skill. Run this once when you want to start using skills.

WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

cd "$WORKSPACE_DIR"

# --- Create .skillshare config and skills directory (only if not already present) ---
if [ ! -d ".skillshare" ]; then
  mkdir -p .skillshare/skills/hello-world

  cat > .skillshare/config.yaml << 'EOF'
# yaml-language-server: $schema=https://raw.githubusercontent.com/runkids/skillshare/main/schemas/project-config.schema.json
targets:
  - claude
  - copilot
  - gemini
  - opencode
  - crush
  - codex
audit:
  block_threshold: CRITICAL
EOF

  cat > .skillshare/skills/hello-world/SKILL.md << 'EOF'
---
name: hello-world
description: A simple greeting skill. Responds with a friendly hello message and the current date and time. Triggered by "/hello-world NAME".
---

# hello-world

Greet the user by name.

## Inputs

`/hello-world NAME`

- `NAME` — the name to greet (e.g. `Alice`, `Bob`)

## Step 1 — Greet the user

Respond with a friendly greeting that includes:
- The name provided
- The current date and time
- A one-sentence encouraging message about learning AI tools

Example output:

```
Hello, Alice!

Today is Wednesday, April 2, 2026 at 10:35 AM.

You're doing great — keep exploring AI agentic tools!
```

Keep the response short and upbeat.
EOF

  echo "Created .skillshare/ with sample hello-world skill."
else
  echo ".skillshare/ already exists — skipping directory creation."
fi

# --- Install skillshare CLI if not already present ---
if ! command -v skillshare >/dev/null 2>&1; then
  echo "Installing skillshare CLI..."
  curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
else
  echo "skillshare CLI already installed."
fi

echo ""
echo "Done. Run scripts/sync-skills.sh to push skills to your AI tools."
