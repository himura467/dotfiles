#!/usr/bin/env bash
#
# Install Zig.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Zig'

if ! command -v zig > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install Zig.'
    fi
  fi
  brew install zig

  success 'Zig installed'
else
  success 'Zig is already installed'
fi