#!/usr/bin/env bash

PI_DIR="$HOME/.pi"
BIN_DIR="$PI_DIR/bin"

if [[ ! -d "$PI_DIR" ]]; then
  echo "✗ $PI_DIR not found. Is pi installed?" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

cp bin/, "$BIN_DIR/,"
cp bin/q "$BIN_DIR/q"
chmod +x "$BIN_DIR/," "$BIN_DIR/q"

echo "✓ Installed , and q to $BIN_DIR"
echo
echo "Add this to your ~/.zshrc if not already present:"
echo '  export PATH="$HOME/.pi/bin:$PATH"'
