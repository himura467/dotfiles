#!/usr/bin/env bash
#
# Install Neovim.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Neovim'

if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install Neovim.'
  fi
fi

brew install neovim

# Install dependencies.
brew install ripgrep

mkdir -p "${XDG_CONFIG_HOME:-$HOME}/.config"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/neovim/nvim" "${XDG_CONFIG_HOME:-$HOME}/.config/nvim"
success 'Neovim installed'
