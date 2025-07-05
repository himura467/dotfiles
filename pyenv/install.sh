#!/usr/bin/env bash
#
# Install pyenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing pyenv'

if command -v brew > /dev/null; then
  brew install pyenv

  success 'pyenv installed'
else
  fail 'Homebrew not found. Homebrew is required to install pyenv.'
fi
