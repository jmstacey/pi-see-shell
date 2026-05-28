# pi-see-shell

A small zsh bridge for Pi.

## What it does
- `q` asks Pi a question and prints the answer in your terminal.
- `,` asks Pi for one shell command, copies it to the clipboard, and does not run it.
- The installer adds a zsh binding so `q` handles apostrophes and question marks cleanly.
- Pi subprocesses stay lean: no skills, extensions, sessions, or prompt templates.

## Install
1. Make sure `pi` is installed and available on your PATH.
2. Clone this repo.
3. Run `./install.sh`.
4. Open a new terminal or source `~/.zshrc`.

The installer copies the scripts into `~/.pi/bin`, adds that directory to PATH, sources the ZLE helper, and sets a per-window `PI_SEE_SHELL_SESSION_ID`.

## Use
- `q what's the weather in Denver, Colorado?`
- `, list files sorted by size with human-readable output`

## Configure
```zsh
export PI_SEE_SHELL_PROVIDER=openrouter
export PI_SEE_SHELL_MODEL=deepseek/deepseek-v4-flash
export PI_SEE_SHELL_THINKING=off
export PI_SEE_SHELL_Q_THINKING=off
export PI_SEE_SHELL_DEBUG_PI_COMMAND=0
```

## Notes
- `,` is suggestion only and does not execute.
- `,` uses `pbcopy`, so macOS is the intended environment.
- Output is kept plain and terminal-friendly.

## Inspiration
- https://z3ugma.github.io/2026/05/25/a-comma-and-a-question-mark/
- https://www.thetypicalset.com/blog/a-comma-and-a-question-mark
