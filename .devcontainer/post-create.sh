#!/bin/bash
set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

cd "$WORKSPACE_DIR"

setup-env.sh
install-mcps.sh || true
