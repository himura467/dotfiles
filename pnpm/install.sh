#!/usr/bin/env bash
#
# Install pnpm.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing pnpm'

if command -v npm > /dev/null; then
  npm install -g pnpm@latest-10

  success 'pnpm installed'
else
  fail 'npm not found. npm is required to install pnpm.'
fi
