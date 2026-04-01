#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"

cd "$WORKSPACE_DIR"

# Generate an SSH key if one doesn't already exist. Used for git operations inside the Codespace.
mkdir -p ~/.ssh && ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' 2>/dev/null || true

# Add ~/.local/bin to PATH so tools installed via pip/pipx are found in the shell.
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
