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
cp "bin/q" "$BIN_DIR/q"
cp "bin/qq" "$BIN_DIR/qq"
cp "bin/qqq" "$BIN_DIR/qqq"
cp "bin/.pi-see-shell-question.zsh" "$BIN_DIR/.pi-see-shell-question.zsh"
cp "bin/.pi-see-shell-zle.zsh" "$BIN_DIR/.pi-see-shell-zle.zsh"
chmod +x "$BIN_DIR/," "$BIN_DIR/,," "$BIN_DIR/q" "$BIN_DIR/qq" "$BIN_DIR/qqq"
rm -f "$BIN_DIR/,,," "$BIN_DIR/?" "$BIN_DIR/??" "$BIN_DIR/???"

if ! grep -Fq 'export PATH="$HOME/.pi/bin:$PATH"' "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# pi-see-shell"
    echo 'export PATH="$HOME/.pi/bin:$PATH"'
    echo '# Optional: choose the Pi provider/model for pi-see-shell'
    echo '# export PI_SEE_SHELL_PROVIDER=openrouter'
    echo '# export PI_SEE_SHELL_MODEL=deepseek/deepseek-v4-flash'
    echo '# export PI_SEE_SHELL_THINKING=off'
    echo '# export PI_SEE_SHELL_Q_THINKING=off'
    echo "# end pi-see-shell"
  } >> "$ZSHRC"
fi

if ! grep -Fq '.pi-see-shell-zle.zsh' "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# pi-see-shell zle bindings"
    echo '[[ -r "$HOME/.pi/bin/.pi-see-shell-zle.zsh" ]] && source "$HOME/.pi/bin/.pi-see-shell-zle.zsh"'
    echo "# end pi-see-shell zle bindings"
  } >> "$ZSHRC"
fi

if ! grep -Fq "alias qq='noglob qq'" "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# pi-see-shell q glob protection"
    echo "alias q='noglob q'"
    echo "alias qq='noglob qq'"
    echo "alias qqq='noglob qqq'"
    echo "# end pi-see-shell q glob protection"
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

echo "✓ Installed , ,, q qq and qqq to $BIN_DIR"
echo
echo "Your shell will now get a per-window PI_SEE_SHELL_SESSION_ID."
echo "Open a new terminal or source ~/.zshrc to activate changes in this shell."
echo "The installer also adds zsh bindings so q/qq/qqq can accept apostrophes and question marks."
echo
echo "Configuration environment variables:"
echo "  PI_SEE_SHELL_PROVIDER   Optional Pi provider, e.g. openrouter"
echo "  PI_SEE_SHELL_MODEL      Optional Pi model, e.g. deepseek/deepseek-v4-flash"
echo "  PI_SEE_SHELL_THINKING     Optional thinking level for command/edit routes, defaults to off"
echo "  PI_SEE_SHELL_Q_THINKING   Optional thinking level for q/qq/qqq, falls back to PI_SEE_SHELL_THINKING"
echo
echo "Examples for ~/.zshrc:"
echo "  export PI_SEE_SHELL_PROVIDER=openrouter"
echo "  export PI_SEE_SHELL_MODEL=deepseek/deepseek-v4-flash"
echo "  export PI_SEE_SHELL_THINKING=off"
echo "  export PI_SEE_SHELL_Q_THINKING=off"
