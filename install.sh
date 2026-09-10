#!/bin/bash
# Install the claude CLI if missing, then copy this repo's config into ~/.claude
set -e
cd "$(dirname "$0")"

# Native installer; auto-updates in the background, unlike an npm global install
if ! command -v claude >/dev/null; then
    echo "claude not found, running the native installer"
    curl -fsSL https://claude.ai/install.sh | bash
    # The installer puts the binary in ~/.local/bin, which may not be on PATH yet
    command -v claude >/dev/null || export PATH="$HOME/.local/bin:$PATH"
fi

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
