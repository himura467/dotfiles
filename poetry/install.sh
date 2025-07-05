#!/usr/bin/env bash
#
# Install Poetry.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Poetry'

if ! command -v poetry > /dev/null; then
  if command -v python > /dev/null; then
    curl -sSL https://install.python-poetry.org | python -

    success 'Poetry installed'
  else
    fail 'Python not found. Python is required to install Poetry.'
  fi
else
  success 'Poetry is already installed'
fi
