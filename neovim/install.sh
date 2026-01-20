#!/usr/bin/env bash
#
# Install Neovim.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Neovim'
if ! command -v nvim > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install Neovim.'
    fi
  fi
  brew install neovim
  success 'Neovim installed'
else
  success 'Neovim is already installed'
fi
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME}/.config/nvim"
info 'Configuring Neovim'
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
  git clone https://github.com/himura467/nvim.git "$NVIM_CONFIG_DIR"
  success 'Neovim configured'
else
  success 'Neovim is already configured'
fi
