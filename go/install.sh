#!/usr/bin/env bash
#
# Install Go.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Go'
if ! command -v go > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install Go.'
    fi
  fi
  brew install go
  success 'Go installed'
else
  success 'Go is already installed'
fi
