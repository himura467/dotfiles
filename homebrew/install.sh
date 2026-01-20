#!/usr/bin/env bash
#
# Install Homebrew.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Homebrew'
if ! command -v brew > /dev/null; then
  if [[ "$(uname -s)" == 'Darwin' ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success 'Homebrew installed'
  else
    fail 'Linux is not supported. Only available on macOS.'
  fi
else
  success 'Homebrew is already installed'
fi
