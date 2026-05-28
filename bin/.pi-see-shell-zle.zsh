# pi-see-shell zsh line editor helpers
# Lets q/qq/qqq accept natural questions like: q what's the weather like?
# by quoting the question text before zsh parses apostrophes or glob chars.

_pi_see_shell_quote_q_buffer() {
  emulate -L zsh

  local line="$BUFFER"
  local leading cmd sep rest

  if [[ "$line" =~ '^([[:space:]]*)((\./)?q{1,3})([[:space:]]+)(.*)$' ]]; then
    leading="$match[1]"
    cmd="$match[2]"
    sep="$match[4]"
    rest="$match[5]"

    [[ -z "$rest" ]] && return 0
    BUFFER="${leading}${cmd}${sep}${(q)rest}"
  fi
}

_pi_see_shell_accept_line() {
  _pi_see_shell_quote_q_buffer
  zle _pi_see_shell_orig_accept_line
}

if [[ -o interactive ]]; then
  if [[ -z "${widgets[_pi_see_shell_orig_accept_line]+x}" ]]; then
    zle -A accept-line _pi_see_shell_orig_accept_line
  fi
  zle -N accept-line _pi_see_shell_accept_line
fi
