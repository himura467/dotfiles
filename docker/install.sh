#!/usr/bin/env bash
#
# Install Docker.

set -e

DOTFILES_ROOT=$(cd $(dirname $0)/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Docker'

if command -v brew > /dev/null; then
  brew install --cask docker

  success 'Docker installed'
else
  fail 'Homebrew not found. Homebrew is required to install Docker.'
fi
