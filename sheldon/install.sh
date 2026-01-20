#!/usr/bin/env bash
#
# Install sheldon.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing sheldon'
if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install sheldon.'
  fi
fi
brew install sheldon
mkdir -p "$HOME/.config/sheldon"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/sheldon/plugins.toml.symlink" "$HOME/.config/sheldon/plugins.toml"
success 'sheldon installed'
