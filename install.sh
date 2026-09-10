#!/bin/bash
# Copy this repo's config into ~/.claude
set -e
cd "$(dirname "$0")"
mkdir -p ~/.claude/themes
cp CLAUDE.md settings.json statusline.sh claude-watch.sh claude-watch-hook.sh ~/.claude/
cp themes/damon.json ~/.claude/themes/
chmod +x ~/.claude/statusline.sh ~/.claude/claude-watch.sh ~/.claude/claude-watch-hook.sh
echo "installed to ~/.claude"

# Append the claude-solo alias to ~/.zshrc if it isn't already there
if ! grep -q "alias claude-solo=" ~/.zshrc 2>/dev/null; then
    printf '\n# claude_cli: run claude without the iTerm2 watcher pane\nalias claude-solo=%s\n' \
        "'CLAUDE_NO_WATCH=1 claude'" >> ~/.zshrc
    echo "added claude-solo alias to ~/.zshrc"
fi
