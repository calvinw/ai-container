#!/bin/bash
set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

cd "$WORKSPACE_DIR"

setup-env.sh
install-mcps.sh || true

# Set up ~/.claude.json for Claude Code to skip onboarding
if [ -f ~/.claude.json ]; then
  jq '. + {"hasCompletedOnboarding":true,"installMethod":"native"}' ~/.claude.json > /tmp/claude.json && mv /tmp/claude.json ~/.claude.json
else
  echo '{"hasCompletedOnboarding":true,"installMethod":"native"}' > ~/.claude.json
fi
