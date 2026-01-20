#!/usr/bin/env bash
#
# Setup Zsh.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Setting up Zsh'
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/zsh/zshrc.symlink" "$HOME/.zshrc"
success 'Zsh set up'
