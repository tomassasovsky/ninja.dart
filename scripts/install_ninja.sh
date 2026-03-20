#!/usr/bin/env bash
# Compile the interactive CLI to a native binary and copy it onto your PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BINARY_NAME="${BINARY_NAME:-ninja}"
STAGING="${STAGING:-$ROOT/build/$BINARY_NAME}"

mkdir -p "$(dirname "$STAGING")"
mkdir -p "$INSTALL_DIR"

dart pub get
dart compile exe bin/ninja.dart -o "$STAGING"
cp "$STAGING" "$INSTALL_DIR/$BINARY_NAME"
chmod 755 "$INSTALL_DIR/$BINARY_NAME"

echo "Installed: $INSTALL_DIR/$BINARY_NAME"
echo "Add to PATH if needed, e.g. export PATH=\"\$HOME/.local/bin:\$PATH\""
