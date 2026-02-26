#!/bin/bash
set -e
echo ""
echo "┌──────────────────────────────────────┐"
echo "│     Installing upterm                │"
echo "└──────────────────────────────────────┘"
echo ""
if command -v upterm &>/dev/null; then
  echo "→ upterm already installed, skipping."
else
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)        ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l)        ARCH="armv6" ;;
    i386|i686)     ARCH="386" ;;
  esac
  TARBALL="upterm_${OS}_${ARCH}.tar.gz"
  echo "→ Downloading $TARBALL..."
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/${TARBALL}" -o "$TMP/upterm.tar.gz"
  tar -xzf "$TMP/upterm.tar.gz" -C "$TMP"
  mv "$TMP/upterm" /usr/local/bin/upterm
  chmod +x /usr/local/bin/upterm
  rm -rf "$TMP"
  echo "✓ upterm installed."
fi
echo ""
echo "To share your terminal with the instructor, run:"
echo ""
echo "  upterm host --accept"
echo ""
