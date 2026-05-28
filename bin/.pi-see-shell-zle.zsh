# pi-see-shell zsh line editor helpers
# Lets q/qq/qqq accept natural questions like: q what's the weather like?
# without showing shell-escaped text in the terminal.

_pi_see_shell_run_q_buffer() {
  emulate -L zsh

  local line="$BUFFER"
  local cmd rest status

  if [[ "$line" =~ '^([[:space:]]*)((\./)?q{1,3})([[:space:]]+)(.*)$' ]]; then
    cmd="$match[2]"
    rest="$match[5]"

    # Preserve the clean, natural command in shell history.
    print -s -- "$line"

    # Clear the edit buffer so zsh does not try to parse apostrophes or globs.
    BUFFER=""
    CURSOR=0

    # Flush the current edit line, move to command output, then invoke directly.
    zle -I
    print -r -- ""
    "$cmd" "$rest"
    status=$?
    print -r -- ""

    # Show a fresh prompt without feeding the original buffer to zsh parsing.
    zle reset-prompt
    return $status
  fi

  return 1
}

_pi_see_shell_accept_line() {
  if _pi_see_shell_run_q_buffer; then
    return
  fi

  zle _pi_see_shell_orig_accept_line
}

if [[ -o interactive ]]; then
  if [[ -z "${widgets[_pi_see_shell_orig_accept_line]+x}" ]]; then
    zle -A accept-line _pi_see_shell_orig_accept_line
  fi
  zle -N accept-line _pi_see_shell_accept_line
fi
