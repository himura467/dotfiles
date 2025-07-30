#!/usr/bin/env bash
#
# Install uv.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing uv'

if ! command -v uv > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install uv.'
    fi
  fi
  brew install uv
  
  success 'uv installed'
else
  success 'uv is already installed'
fi

user 'Would you like to install a specific Python version? (y/n)'
read -r -p '> ' install_python

if [[ "$install_python" =~ ^[Yy]$ ]]; then
  available_versions=$(uv python list --all-versions | grep '^cpython-' | sed 's/cpython-\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/' | sort -V -u | tail -100)
  
  user 'Which Python version would you like to install?'
  info 'Available versions (showing latest 100):'
  info_list "$available_versions"
  read -r -p '> ' python_version
  
  if echo "$available_versions" | grep -q "^$python_version$"; then
    info "Installing Python $python_version"
    uv python install "$python_version"
    
    success "Python $python_version installed"
  else
    fail 'Invalid Python version. Please choose from the available versions listed above.'
  fi
fi
