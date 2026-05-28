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

pi_see_shell_target_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin) printf '%s\n' "macOS" ;;
    Linux) printf '%s\n' "Linux" ;;
    *) printf '%s\n' "unknown OS" ;;
  esac
}

pi_see_shell_system_prompt() {
  local mode="${1:-concise}"
  local target_os="${2:-$(pi_see_shell_target_os)}"
  case "$mode" in
    exhaustive)
      printf '%s\n' "You are a thorough, exhaustive research assistant for ${target_os} terminal use. Give a comprehensive, detailed answer for terminal display. Use clean plain text, not Markdown. Avoid Markdown headings, tables, bold/italic markers, fenced code blocks, and decorative formatting. Short plain-text sections and simple hyphen bullets are okay when helpful. Cover edge cases, nuances, alternatives, and follow-on considerations. Use web search and file reading to gather full context before answering. Do not run bash commands."
      ;;
    *)
      printf '%s\n' "You are a helpful, concise assistant for ${target_os} terminal use. Answer clearly and accurately for terminal display. Use clean plain text, not Markdown. Avoid Markdown headings, tables, bold/italic markers, fenced code blocks, and decorative formatting. Short plain-text bullets are okay when useful. Use web search or file reading when needed. Do not run bash commands."
      ;;
  esac
}

pi_see_shell_plain_text() {
  local input_file
  input_file="$(mktemp)"
  cat > "$input_file"

  python3 - "$input_file" <<'PY'
import pathlib, re, sys

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')

# Remove fenced-code markers but keep the content between them.
text = re.sub(r'^```[A-Za-z0-9_-]*\s*$', '', text, flags=re.MULTILINE)

# Remove common inline Markdown markers.
text = text.replace('**', '')
text = text.replace('__', '')
text = re.sub(r'`([^`]+)`', r'\1', text)

lines = text.splitlines()
out = []
pending_table_header = None
in_table = False

def table_cells(line: str):
    stripped = line.strip()
    if not (stripped.startswith('|') and stripped.endswith('|')):
        return None
    return [cell.strip() for cell in stripped.strip('|').split('|')]

def is_separator(cells):
    return bool(cells) and all(re.fullmatch(r':?-{3,}:?', cell.replace(' ', '')) for cell in cells)

i = 0
while i < len(lines):
    line = lines[i]
    line = re.sub(r'^\s{0,3}#{1,6}\s+', '', line)

    cells = table_cells(line)
    if cells is not None:
        next_cells = table_cells(lines[i + 1]) if i + 1 < len(lines) else None
        if next_cells is not None and is_separator(next_cells):
            pending_table_header = cells
            in_table = True
            i += 2
            continue
        if in_table and pending_table_header and len(cells) == len(pending_table_header):
            out.append('- ' + '; '.join(f'{h}: {c}' for h, c in zip(pending_table_header, cells)))
            i += 1
            continue
        out.append('- ' + '; '.join(cells))
        i += 1
        continue

    if in_table and line.strip() == '':
        in_table = False
        pending_table_header = None

    out.append(line)
    i += 1

result = '\n'.join(out)
result = re.sub(r'\n{3,}', '\n\n', result).strip()
print(result)
PY

  local plain_status=$?
  rm -f "$input_file"
  return $plain_status
}

pi_see_shell_extract_command() {
  local input_file
  input_file="$(mktemp)"
  cat > "$input_file"

  python3 - "$input_file" <<'PY'
import json, pathlib, re, sys

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').strip()

def emit(value: str):
    value = value.strip()
    if value:
        print(value)
    raise SystemExit(0)

def strip_markers(t: str) -> str:
    t = re.sub(r'^```[A-Za-z0-9_-]*\s*$', '', t, flags=re.MULTILINE)
    t = t.replace('**', '')
    t = t.replace('__', '')
    t = re.sub(r'`([^`]+)`', r'\1', t)
    return t.strip()

def emit_json_command(blob: str) -> bool:
    try:
        data = json.loads(blob)
    except Exception:
        return False
    if isinstance(data, dict):
        cmd = data.get('command')
        if isinstance(cmd, str) and cmd.strip():
            emit(cmd)
    return False

emit_json_command(text)

m = re.search(r'\{.*\}', text, flags=re.S)
if m:
    emit_json_command(m.group(0))

for block in re.findall(r'```(?:bash|sh|zsh|shell)?\s*(.*?)```', text, flags=re.S | re.I):
    lines = [line.strip() for line in block.splitlines() if line.strip()]
    if lines:
        emit(lines[0])

text = strip_markers(text)
lines = [line.strip() for line in text.splitlines() if line.strip()]

label_prefixes = ('suggested command:', 'command:', 'answer:', 'result:', 'output:')
command_starters = re.compile(r'^(?:\.{1,2}/|/|(?:cd|ls|find|grep|rg|du|git|curl|wget|awk|sed|perl|python3?|node|npm|pnpm|yarn|make|brew|docker|kubectl|ssh|scp|rsync|mv|cp|rm|mkdir|chmod|chown|tar|unzip|zip|open|pbcopy|printf|echo|cat|touch|xargs|sudo)\b)')

for line in lines:
    lower = line.lower()
    matched_label = False
    for prefix in label_prefixes:
        if lower == prefix:
            matched_label = True
            break
        if lower.startswith(prefix):
            remainder = line[len(prefix):].strip(' :-')
            if remainder:
                emit(remainder)
            matched_label = True
            break
    if matched_label:
        continue

    if command_starters.match(line):
        emit(line)

if lines:
    emit(lines[0])

print('')
PY

  local extract_status=$?
  rm -f "$input_file"
  return $extract_status
}


pi_see_shell_write_mode() {
  local mode="$1"
  local state_file
  state_file="$(pi_see_shell_meta_path)"
  pi_see_shell_ensure_session_dir
  python3 - "$state_file" "$mode" <<'PY'
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
  local state_file
  state_file="$(pi_see_shell_meta_path)"
  if [[ ! -f "$state_file" ]]; then
    printf '%s\n' "concise"
    return
  fi

  python3 - "$state_file" <<'PY'
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
  local transcript_file
  transcript_file="$(pi_see_shell_transcript_path)"
  pi_see_shell_ensure_session_dir
  : > "$transcript_file"
}

pi_see_shell_append_turn() {
  local role="$1"
  local transcript_file
  transcript_file="$(pi_see_shell_transcript_path)"
  pi_see_shell_ensure_session_dir
  python3 -c 'import json, pathlib, sys; path = pathlib.Path(sys.argv[1]); role = sys.argv[2]; content = sys.stdin.read(); path.parent.mkdir(parents=True, exist_ok=True); path.open("a", encoding="utf-8").write(json.dumps({"role": role, "content": content}, ensure_ascii=False) + "\n")' "$transcript_file" "$role"
}

pi_see_shell_render_markdown() {
  if [[ -t 1 ]] && command -v glow >/dev/null 2>&1; then
    local style="${PI_SEE_SHELL_GLOW_STYLE:-notty}"
    local width="${PI_SEE_SHELL_GLOW_WIDTH:-}"
    if [[ -z "$width" ]] && command -v tput >/dev/null 2>&1; then
      width="$(tput cols 2>/dev/null || true)"
    fi
    [[ -z "$width" ]] && width=88
    glow --style "$style" --width "$width" -
  else
    cat
  fi
}



pi_see_shell_quote_double() {
  local value="$1"
  value="${(qqq)value}"
  value="${value//!/\\!}"
  printf '%s' "$value"
}

pi_see_shell_debug_pi_command() {
  case "${PI_SEE_SHELL_DEBUG_PI_COMMAND:-}" in
    1|true|TRUE|yes|YES|on|ON) ;;
    *) return 0 ;;
  esac

  local -a args=("$@")
  local output=""
  local quote_next=0
  local arg

  for arg in "${args[@]}"; do
    if (( quote_next )); then
      output+="${output:+ }$(pi_see_shell_quote_double "$arg")"
      quote_next=0
      continue
    fi

    if [[ "$arg" == --system-prompt ]]; then
      output+="${output:+ }$arg"
      quote_next=1
      continue
    fi

    if [[ -n "$arg" && "$arg" != *[!A-Za-z0-9_./:@%+=,~-]* ]]; then
      output+="${output:+ }$arg"
    else
      output+="${output:+ }$(pi_see_shell_quote_double "$arg")"
    fi
  done

  print -u2 -r -- "$output"
}


pi_see_shell_openrouter_preset_extension_path() {
  printf '%s\n' "$HOME/.pi/agent/extensions/openrouter-preset.ts"
}

pi_see_shell_followup_prompt() {
  local question="$1"
  local transcript_file
  transcript_file="$(pi_see_shell_transcript_path)"
  python3 - "$transcript_file" "$question" <<'PY'
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
