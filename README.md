# claude_cli

Personal Claude Code config. Run `./install.sh` to copy into `~/.claude`.

| File | Purpose |
|---|---|
| CLAUDE.md | Global rules |
| settings.json | Model, fullscreen TUI, theme, status line, SessionStart hook |
| themes/damon.json | Custom color theme |
| statusline.sh | Status line: model, dir, git branch, context bar, cost, limits |
| claude-watch-hook.sh | SessionStart hook: in iTerm2, opens a right pane running the watcher |
| claude-watch.sh | Tails the session log: thinking, commands, PR-style edit diffs, tool output. Exits and closes its pane when claude exits |

Just run `claude` in iTerm2. The watcher pane opens on startup and closes when claude exits.
