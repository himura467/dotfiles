#!/usr/bin/env bash
#
# Install sheldon.

set -e

DOTFILES_ROOT=$(cd $(dirname $0)/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Installing sheldon'

if command -v brew > /dev/null; then
  brew install sheldon

  mkdir -p "$HOME/.config/sheldon"
  overwrite_all=false backup_all=false skip_all=false
  link_file "$DOTFILES_ROOT/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
  success 'sheldon installed'
else
  fail 'Homebrew not found. Homebrew is required to install sheldon.'
fi
