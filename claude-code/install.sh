#!/usr/bin/env bash
#
# Install Claude Code.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Claude Code'
if ! command -v claude > /dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
  success 'Claude Code installed'
else
  success 'Claude Code is already installed'
fi
mkdir -p "$HOME/.claude"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/claude-code/CLAUDE.md.symlink" "$HOME/.claude/CLAUDE.md"
for skill_dir in "$DOTFILES_ROOT/claude-code/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$HOME/.claude/skills/$skill_name"
  link_file "${skill_dir}SKILL.md.symlink" "$HOME/.claude/skills/$skill_name/SKILL.md"
done
success 'Claude Code set up'
