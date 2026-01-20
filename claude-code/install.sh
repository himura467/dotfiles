#!/usr/bin/env bash
#
# Install Claude Code.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Claude Code'
curl -fsSL https://claude.ai/install.sh | bash
mkdir -p "$HOME/.claude"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/claude-code/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
success 'Claude Code installed'
