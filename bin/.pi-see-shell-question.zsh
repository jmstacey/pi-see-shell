pi_see_shell_state_dir() {
  printf '%s\n' "${PI_SEE_SHELL_STATE_DIR:-$HOME/.pi-see-shell}"
}

pi_see_shell_session_id() {
  if [[ -n "${PI_SEE_SHELL_SESSION_ID:-}" ]]; then
    printf '%s\n' "$PI_SEE_SHELL_SESSION_ID"
    return
  fi

  local tty_name
  tty_name="$(tty 2>/dev/null || true)"
  if [[ -n "$tty_name" && "$tty_name" != "not a tty" ]]; then
    printf '%s\n' "${tty_name//\//_}"
  else
    printf '%s\n' "default"
  fi
}

pi_see_shell_session_dir() {
  printf '%s/sessions/%s\n' "$(pi_see_shell_state_dir)" "$(pi_see_shell_session_id)"
}

pi_see_shell_transcript_path() {
  printf '%s/last-question.jsonl\n' "$(pi_see_shell_session_dir)"
}

pi_see_shell_meta_path() {
  printf '%s/last-question.meta.json\n' "$(pi_see_shell_session_dir)"
}

pi_see_shell_ensure_session_dir() {
  mkdir -p "$(pi_see_shell_session_dir)"
}

pi_see_shell_system_prompt() {
  case "$1" in
    exhaustive)
      printf '%s\n' "You are a thorough, exhaustive research assistant in a macOS terminal. Give a comprehensive, detailed answer. Cover edge cases, nuances, alternatives, and follow-on considerations. Use web search and file reading to gather full context before answering. Do not run bash commands."
      ;;
    *)
      printf '%s\n' "You are a helpful, concise assistant in a macOS terminal. Answer clearly and accurately. Use web search or file reading when needed. Do not run bash commands."
      ;;
  esac
}

pi_see_shell_write_mode() {
  local mode="$1"
  local path
  path="$(pi_see_shell_meta_path)"
  pi_see_shell_ensure_session_dir
  python3 - "$path" "$mode" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
mode = sys.argv[2]
path.parent.mkdir(parents=True, exist_ok=True)
tmp = path.with_suffix(path.suffix + '.tmp')
tmp.write_text(json.dumps({"mode": mode}, ensure_ascii=False, indent=2) + "\n", encoding='utf-8')
tmp.replace(path)
PY
}

pi_see_shell_read_mode() {
  local path
  path="$(pi_see_shell_meta_path)"
  if [[ ! -f "$path" ]]; then
    printf '%s\n' "concise"
    return
  fi

  python3 - "$path" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding='utf-8'))
except Exception:
    print('concise')
    raise SystemExit(0)
mode = data.get('mode', 'concise') if isinstance(data, dict) else 'concise'
print(mode if mode in {'concise', 'exhaustive'} else 'concise')
PY
}

pi_see_shell_reset_transcript() {
  local path
  path="$(pi_see_shell_transcript_path)"
  pi_see_shell_ensure_session_dir
  : > "$path"
}

pi_see_shell_append_turn() {
  local role="$1"
  local path
  path="$(pi_see_shell_transcript_path)"
  pi_see_shell_ensure_session_dir
  python3 -c 'import json, pathlib, sys; path = pathlib.Path(sys.argv[1]); role = sys.argv[2]; content = sys.stdin.read(); path.parent.mkdir(parents=True, exist_ok=True); path.open("a", encoding="utf-8").write(json.dumps({"role": role, "content": content}, ensure_ascii=False) + "\n")' "$path" "$role"
}

pi_see_shell_followup_prompt() {
  local question="$1"
  local path
  path="$(pi_see_shell_transcript_path)"
  python3 - "$path" "$question" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
question = sys.argv[2]
turns = []
if path.exists():
    for line in path.read_text(encoding='utf-8').splitlines():
        try:
            turn = json.loads(line)
        except Exception:
            continue
        if isinstance(turn, dict) and turn.get('role') in {'user', 'assistant'} and turn.get('content'):
            turns.append(turn)
if not turns:
    print(question)
else:
    transcript = '\n\n'.join(f"{turn['role']}:\n{turn['content']}" for turn in turns)
    print('Continue the previous shell discussion.')
    print()
    print('Transcript so far:')
    print(transcript)
    print()
    print('Follow-up question:')
    print(question)
PY
}
