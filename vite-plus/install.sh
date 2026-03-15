#!/usr/bin/env bash
#
# Install Vite+.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Vite+'
if ! command -v vp > /dev/null; then
  curl -fsSL https://vite.plus | bash
  success 'Vite+ installed'
else
  success 'Vite+ is already installed'
fi
