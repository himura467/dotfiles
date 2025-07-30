#!/usr/bin/env bash
#
# Install 1Password CLI.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing 1Password CLI'

if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install 1Password CLI.'
  fi
fi

if ! command -v op > /dev/null; then
  brew install 1password-cli

  success '1Password CLI installed'
else
  success '1Password CLI is already installed'
fi
