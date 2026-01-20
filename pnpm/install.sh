#!/usr/bin/env bash
#
# Install pnpm.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing pnpm'
if ! command -v npm > /dev/null; then
  user 'npm not found. Would you like to install Node.js/npm first? (y/n)'
  read -r -p '> ' install_node
  if [[ "$install_node" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/nodenv/install.sh"
    source "$DOTFILES_ROOT/nodenv/path.zsh"
  else
    fail 'npm is required to install pnpm.'
  fi
fi
npm install -g pnpm@latest-10
nodenv rehash
success 'pnpm installed'
