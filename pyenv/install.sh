#!/usr/bin/env bash
#
# Install pyenv.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing pyenv'

if ! command -v pyenv > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install pyenv.'
    fi
  fi
  brew install pyenv
  
  success 'pyenv installed'
else
  success 'pyenv is already installed'
fi

source "$DOTFILES_ROOT/pyenv/path.zsh"

user 'Would you like to install a specific Python version? (y/n)'
read -r -p '> ' install_python

if [[ "$install_python" =~ ^[Yy]$ ]]; then
  available_versions=$(pyenv install --list | grep -E '^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^[[:space:]]*//' | tail -100)
  
  user 'Which Python version would you like to install?'
  info 'Available versions (showing latest 100):'
  info_list "$available_versions"
  read -r -p '> ' python_version
  
  if echo "$available_versions" | grep -q "^$python_version$"; then
    info "Installing Python $python_version"
    pyenv install "$python_version"
    
    user "Would you like to set Python $python_version as the global default? (y/n)"
    read -r -p '> ' set_global
    
    if [[ "$set_global" =~ ^[Yy]$ ]]; then
      pyenv global "$python_version"
      success "Python $python_version set as global default"
    fi
    
    success "Python $python_version installed"
  else
    fail 'Invalid Python version. Please choose from the available versions listed above.'
  fi
fi
