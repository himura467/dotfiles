#!/usr/bin/env bash
#
# Upgrade Homebrew.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Upgrading Homebrew'

if command -v brew > /dev/null; then
  brew update
  brew upgrade
  brew upgrade --cask

  success 'Homebrew upgraded'
else
  fail 'Homebrew not found. Homebrew is required to upgrade Homebrew.'
fi
