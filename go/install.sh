#!/usr/bin/env bash
#
# Install Go.

set -e

DOTFILES_ROOT=$(pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Go'

if command -v brew > /dev/null; then
  brew install go

  success 'Go installed'
else
  fail 'Homebrew not found. Homebrew is required to install Go.'
fi
