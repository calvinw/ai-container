#!/bin/bash
set -euo pipefail

# Uninstalls all synced skills from AI tools, leaving them only in .skillshare/.
# Run this after testing to clean up. Re-run sync-skills.sh to redeploy.

WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

cd "$WORKSPACE_DIR"

if [ ! -d ".skillshare" ]; then
  echo "No .skillshare directory found — nothing to uninstall."
  exit 0
fi

if ! command -v skillshare >/dev/null 2>&1; then
  echo "skillshare CLI not found. Run scripts/setup-skills.sh first."
  exit 1
fi

skillshare uninstall
