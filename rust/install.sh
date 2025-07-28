#!/usr/bin/env bash
#
# Install Rust.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Rust'

if ! command -v rustup > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install rustup.'
    fi
  fi
  brew install rustup-init
  rustup-init -y
  
  success 'Rust installed'
else
  success 'Rust is already installed'
fi

user 'Would you like to install additional Rust components? (y/n)'
read -r -p '> ' install_components

if [[ "$install_components" =~ ^[Yy]$ ]]; then
  components=('clippy' 'rustfmt' 'rust-analyzer')
  
  for component in "${components[@]}"; do
    user "Install $component? (y/n)"
    read -r -p '> ' install_component
    
    if [[ "$install_component" =~ ^[Yy]$ ]]; then
      info "Installing $component"
      rustup component add "$component"

      success "$component installed"
    fi
  done
fi
