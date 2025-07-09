#!/usr/bin/env bash
#
# Install Homebrew.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Homebrew'

if [[ "$(uname -s)" == 'Darwin' ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  success 'Homebrew installed'
else
  fail 'Linux is not supported. Only available on macOS.'
fi
