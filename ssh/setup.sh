#!/usr/bin/env bash
#
# Setup SSH.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Setting up SSH'
mkdir -p "$HOME/.ssh"
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/ssh/config.symlink" "$HOME/.ssh/config"
success 'SSH set up'
