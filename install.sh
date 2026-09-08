#!/bin/bash
# Copy this repo's config into ~/.claude
set -e
cd "$(dirname "$0")"
mkdir -p ~/.claude/themes
cp CLAUDE.md settings.json statusline.sh claude-watch.sh claude-watch-hook.sh ~/.claude/
cp themes/damon.json ~/.claude/themes/
chmod +x ~/.claude/statusline.sh ~/.claude/claude-watch.sh ~/.claude/claude-watch-hook.sh
echo "installed to ~/.claude"
