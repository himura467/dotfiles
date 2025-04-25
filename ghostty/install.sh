#!/usr/bin/env bash
#
# Install Ghostty.

set -e

DOTFILES_ROOT=$(cd $(dirname $0)/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing Ghostty'

if command -v brew > /dev/null; then
  brew install --cask ghostty

  mkdir -p "$HOME/.config/ghostty"
  link_file "$DOTFILES_ROOT/ghostty/config" "$HOME/.config/ghostty/config"
  success 'Ghostty installed'
else
  fail 'Homebrew not found. Homebrew is required to install Ghostty.'
fi
