#!/usr/bin/env bash

PI_DIR="$HOME/.pi"
BIN_DIR="$PI_DIR/bin"
ZSHRC="$HOME/.zshrc"

if [[ ! -d "$PI_DIR" ]]; then
  echo "✗ $PI_DIR not found. Is pi installed?" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

cp "bin/," "$BIN_DIR/,"
cp "bin/,," "$BIN_DIR/,,"
cp "bin/,,," "$BIN_DIR/,,,"
cp "bin/?" "$BIN_DIR/?"
cp "bin/??" "$BIN_DIR/??"
cp "bin/???" "$BIN_DIR/???"
cp "bin/.pi-see-shell-question.zsh" "$BIN_DIR/.pi-see-shell-question.zsh"
chmod +x "$BIN_DIR/," "$BIN_DIR/,," "$BIN_DIR/,,," "$BIN_DIR/?" "$BIN_DIR/??" "$BIN_DIR/???"

if ! grep -Fq 'export PATH="$HOME/.pi/bin:$PATH"' "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# pi-see-shell"
    echo 'export PATH="$HOME/.pi/bin:$PATH"'
    echo '# Optional: choose the Pi provider/model for pi-see-shell'
    echo '# export PI_SEE_SHELL_PROVIDER=openrouter'
    echo '# export PI_SEE_SHELL_MODEL=deepseek/deepseek-v4-flash'
    echo '# export PI_SEE_SHELL_THINKING=off'
    echo "# end pi-see-shell"
  } >> "$ZSHRC"
fi

if ! grep -Fq 'PI_SEE_SHELL_SESSION_ID' "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# pi-see-shell session id"
    echo 'if [[ -z "${PI_SEE_SHELL_SESSION_ID:-}" ]]; then'
    echo '  if command -v uuidgen >/dev/null 2>&1; then'
    echo '    export PI_SEE_SHELL_SESSION_ID="$(uuidgen)"'
    echo '  elif command -v python3 >/dev/null 2>&1; then'
    echo "    export PI_SEE_SHELL_SESSION_ID=\"\$(python3 -c 'import uuid; print(uuid.uuid4())')\""
    echo '  else'
    echo '    export PI_SEE_SHELL_SESSION_ID="$$"'
    echo '  fi'
    echo 'fi'
    echo "# end pi-see-shell session id"
  } >> "$ZSHRC"
fi

echo "✓ Installed , ,, ,,, ? ?? and ??? to $BIN_DIR"
echo
echo "Your shell will now get a per-window PI_SEE_SHELL_SESSION_ID."
echo "Set PI_SEE_SHELL_PROVIDER, PI_SEE_SHELL_MODEL, and PI_SEE_SHELL_THINKING to tune Pi."
echo "Open a new terminal or source ~/.zshrc to activate changes in this shell."
echo
echo "💡 Pro tip: Create a lightweight pi profile to keep startup fast."
echo "   A minimal profile with no extensions loads much quicker — ideal for"
echo "   quick command lookups and one-shot questions. In that profile, set"
echo "   your preferred model and provider for low-latency responses, or set"
echo '   PI_SEE_SHELL_PROVIDER, PI_SEE_SHELL_MODEL, and PI_SEE_SHELL_THINKING in ~/.zshrc.'
