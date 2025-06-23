#!/usr/bin/env bash
#
# Install direnv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing direnv'

if command -v brew > /dev/null; then
  brew install direnv

  success 'direnv installed'
else
  fail 'Homebrew not found. Homebrew is required to install direnv.'
fi
