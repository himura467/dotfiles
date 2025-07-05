#!/usr/bin/env bash
#
# Install tfenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing tfenv'

if command -v brew > /dev/null; then
  brew install tfenv

  success 'tfenv installed'
else
  fail 'Homebrew not found. Homebrew is required to install tfenv.'
fi
