#!/usr/bin/env bash
#
# Install Ghostty.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Ghostty'
if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install Ghostty.'
  fi
fi
brew install --cask ghostty
mkdir -p "$HOME/.config/ghostty"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/ghostty/config.symlink" "$HOME/.config/ghostty/config"
success 'Ghostty installed'
