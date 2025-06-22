#!/usr/bin/env bash
#
# Install Claude Code.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Claude Code'

if command -v pnpm > /dev/null; then
  pnpm add -g @anthropic-ai/claude-code

  success 'Claude Code installed'
else
  fail 'pnpm not found. pnpm is required to install Claude Code.'
fi
