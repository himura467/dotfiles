#!/usr/bin/env bash
#
# Install Poetry.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Poetry'

if ! command -v poetry > /dev/null; then
  if ! command -v python > /dev/null; then
    user 'Python not found. Would you like to install Python first? (y/n)'
    read -r -p '> ' install_python
    
    if [[ "$install_python" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/pyenv/install.sh"
      source "$DOTFILES_ROOT/pyenv/path.zsh"
    else
      fail 'Python is required to install Poetry.'
    fi
  fi
  curl -sSL https://install.python-poetry.org | python -

  success 'Poetry installed'
else
  success 'Poetry is already installed'
fi
