#!/bin/bash
set -e

# Generate an SSH key if one doesn't already exist.
mkdir -p ~/.ssh && ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' >/dev/null 2>&1 || true

# Add ~/.local/bin to PATH so tools installed via pip/pipx are found in the shell.
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
