#!/usr/bin/env bash
#
# Install 1Password CLI.

set -e

DOTFILES_ROOT=$(cd $(dirname $0)/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing 1Password CLI'

if command -v brew > /dev/null; then
  if ! command -v op > /dev/null; then
    brew install 1password-cli

    success '1Password CLI installed'
  else
    success '1Password CLI is already installed'
  fi
else
  fail 'Homebrew not found. Homebrew is required to install 1Password CLI.'
fi
