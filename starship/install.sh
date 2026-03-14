#!/usr/bin/env bash
#
# Install Starship.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Starship'
if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install Starship.'
    exit 1
  fi
fi
brew install starship
mkdir -p "$HOME/.config"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/starship/starship.toml.symlink" "$HOME/.config/starship.toml"
success 'Starship installed'
