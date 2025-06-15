#!/usr/bin/env bash
#
# Install Raycast.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Raycast'

if command -v brew > /dev/null; then
  brew install --cask raycast

  success 'Raycast installed'
else
  fail 'Homebrew not found. Homebrew is required to install Raycast.'
fi
