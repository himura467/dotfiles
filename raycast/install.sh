#!/usr/bin/env bash
#
# Install Raycast.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Raycast'

if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install Raycast.'
  fi
fi

brew install --cask raycast

success 'Raycast installed'
