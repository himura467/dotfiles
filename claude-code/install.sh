#!/usr/bin/env bash
#
# Install Claude Code.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Claude Code'

if command -v pnpm > /dev/null; then
  pnpm add -g @anthropic-ai/claude-code

  mkdir -p "$HOME/.claude"
  overwrite_all=false backup_all=false skip_all=false
  link_file "$DOTFILES_ROOT/claude-code/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  success 'Claude Code installed'
else
  fail 'pnpm not found. pnpm is required to install Claude Code.'
fi
