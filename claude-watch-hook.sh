#!/bin/bash
# SessionStart hook: open a right-hand iTerm2 pane running claude-watch.sh.
# The watcher gets the claude PID so it exits (and its pane closes) when claude does.
[ "$TERM_PROGRAM" = "iTerm.app" ] || exit 0
PROJ=$(jq -r '.cwd // empty')
[ -n "$PROJ" ] || PROJ="$PWD"

# walk up the process tree to the claude process
PID=$$
while [ "$PID" -gt 1 ]; do
  PID=$(ps -o ppid= -p "$PID" | tr -d ' ')
  [ "$(ps -o comm= -p "$PID")" = "claude" ] && break
done

osascript <<APPLESCRIPT
tell application "iTerm2"
  tell current session of current window
    set w to (split vertically with default profile)
    tell w to write text "$HOME/.claude/claude-watch.sh '$PROJ' $PID; exit"
  end tell
end tell
APPLESCRIPT
