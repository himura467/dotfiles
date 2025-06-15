#!/usr/bin/env bash
#
# Install Go.

set -e

DOTFILES_ROOT=$(pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Go'

if ! command -v go > /dev/null; then
  if command -v brew > /dev/null; then
    brew install go

    success 'Go installed'
  else
    fail 'Homebrew not found. Homebrew is required to install Go.'
  fi
else
  success 'Go is already installed'
fi

if ! command -v wire > /dev/null; then
  user 'Do you want to install Wire?'
  read -r -p '[Y/n] ' yn
  case "$yn" in
    [Nn]* )
      info 'Skipping Wire installation'
      ;;
    * )
      info 'Installing Wire'
      go install github.com/google/wire/cmd/wire@latest
      success 'Wire installed successfully'
      ;;
  esac
fi
