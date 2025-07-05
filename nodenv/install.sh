#!/usr/bin/env bash
#
# Install nodenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing nodenv'

if ! command -v nodenv > /dev/null; then
  if command -v brew > /dev/null; then
    brew install nodenv

    success 'nodenv installed'
  else
    fail 'Homebrew not found. Homebrew is required to install nodenv.'
  fi
else
  success 'nodenv is already installed'
fi

source "$DOTFILES_ROOT/nodenv/path.zsh"

user 'Would you like to install a specific Node.js version? (y/n)'
read -r -p '> ' install_node

if [[ "$install_node" =~ ^[Yy]$ ]]; then
  available_versions=$(nodenv install --list | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -10)
  
  user "Which Node.js version would you like to install?\n\
Available versions (showing latest 10):\n$available_versions"
  read -r -p '> ' node_version
  
  if echo "$available_versions" | grep -q "^$node_version$"; then
    info "Installing Node.js $node_version"
    nodenv install "$node_version"
    
    user "Would you like to set Node.js $node_version as the global default? (y/n)"
    read -r -p '> ' set_global
    
    if [[ "$set_global" =~ ^[Yy]$ ]]; then
      nodenv global "$node_version"
      success "Node.js $node_version set as global default"
    fi
    
    success "Node.js $node_version installed"
  else
    fail 'Invalid Node.js version. Please choose from the available versions listed above.'
  fi
fi
