#!/usr/bin/env bash
#
# Install tfenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing tfenv'

if ! command -v tfenv > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew
    
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install tfenv.'
    fi
  fi
  brew install tfenv
  
  success 'tfenv installed'
else
  success 'tfenv is already installed'
fi

user "Would you like to install a specific Terraform version? (y/n)"
read -r -p '> ' install_terraform

if [[ "$install_terraform" =~ ^[Yy]$ ]]; then
  available_versions=$(tfenv list-remote | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -10)
  
  user "Which Terraform version would you like to install?\n\
Available versions (showing latest 10):\n$available_versions"
  read -r -p '> ' terraform_version
  
  if echo "$available_versions" | grep -q "^$terraform_version$"; then
    info "Installing Terraform $terraform_version"
    tfenv install "$terraform_version"
    
    user "Would you like to set Terraform $terraform_version as the global default? (y/n)"
    read -r -p '> ' set_global
    
    if [[ "$set_global" =~ ^[Yy]$ ]]; then
      tfenv use "$terraform_version"
      success "Terraform $terraform_version set as global default"
    fi
    
    success "Terraform $terraform_version installed"
  else
    fail 'Invalid Terraform version. Please choose from the available versions listed above.'
  fi
fi
