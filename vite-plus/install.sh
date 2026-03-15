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
source "$DOTFILES_ROOT/vite-plus/path.zsh"
user 'Would you like to install a specific Node.js version? (y/n)'
read -r -p '> ' install_node
if [[ "$install_node" =~ ^[Yy]$ ]]; then
  available_versions=$(vp env list-remote --lts | tail -10)
  user 'Which Node.js version would you like to install?'
  info 'Available versions (showing latest 10 LTS):'
  info_list "$available_versions"
  read -r -p '> ' node_version
  info "Installing Node.js $node_version"
  vp env install "$node_version"
  user "Would you like to set Node.js $node_version as the global default? (y/n)"
  read -r -p '> ' set_global
  if [[ "$set_global" =~ ^[Yy]$ ]]; then
    vp env default "$node_version"
    success "Node.js $node_version set as global default"
  fi
  success "Node.js $node_version installed"
fi
