#!/usr/bin/env bash
#
# Install Vite+.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Vite+'
curl -fsSL https://vite.plus | bash
success 'Vite+ installed'
