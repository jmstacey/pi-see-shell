pi-see-shell

A small zsh bridge for Pi.

What it does
- `q` asks Pi a question and prints the answer in your terminal.
- `,` asks Pi for one shell command, copies it, and does not run it.
- `q` gets a zsh binding so natural text with apostrophes and question marks works cleanly.
- Everything stays lean. No sessions. No context files. No skills. No prompt templates.

Install
1. Make sure `pi` is installed and available on your PATH.
2. Run `./install.sh` from this repo.
3. Open a new terminal or source `~/.zshrc`.

The installer copies the scripts into `~/.pi/bin`, adds that directory to PATH, sources the zle helper, and sets a per-window `PI_SEE_SHELL_SESSION_ID`.

Use
- `q what's the fastest way to rename these files?`
- `, show me a command to list hidden files`

Configure
- `PI_SEE_SHELL_PROVIDER`
- `PI_SEE_SHELL_MODEL`
- `PI_SEE_SHELL_THINKING`
- `PI_SEE_SHELL_Q_THINKING`
- `PI_SEE_SHELL_DEBUG_PI_COMMAND`

Notes
- `,` is suggestion only.
- The `,` route uses `pbcopy`, so macOS is the intended home.
- Output is kept plain and terminal-friendly.

Inspiration
- https://z3ugma.github.io/2026/05/25/a-comma-and-a-question-mark/
- https://www.thetypicalset.com/blog/a-comma-and-a-question-mark
