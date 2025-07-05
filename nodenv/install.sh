#!/usr/bin/env bash
#
# Install nodenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing nodenv'

if ! command -v nodenv > /dev/null; then
  brew install nodenv

  success 'nodenv installed'
else
  success 'nodenv is already installed'
fi
