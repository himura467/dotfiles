#!/usr/bin/env bash
#
# Install plenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing plenv'

if ! command -v plenv > /dev/null; then
  git clone https://github.com/tokuhirom/plenv.git ~/.plenv
  git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/

  success 'plenv installed'
else
  success 'plenv is already installed'
fi

source "$DOTFILES_ROOT/plenv/path.zsh"

user 'Would you like to install a specific Perl version? (y/n)'
read -r -p '> ' install_perl

if [[ "$install_perl" =~ ^[Yy]$ ]]; then
  available_versions=$(plenv install --list | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -10)
  
  user "Which Perl version would you like to install?\n\
  Available versions (showing latest 10):\n$available_versions"
  read -r -p '> ' perl_version
  
  if echo "$available_versions" | grep -q "^$perl_version$"; then
    info "Installing Perl $perl_version"
    plenv install "$perl_version"
    
    user "Would you like to set Perl $perl_version as the global default? (y/n)"
    read -r -p '> ' set_global
    
    if [[ "$set_global" =~ ^[Yy]$ ]]; then
      plenv global "$perl_version"
      success "Perl $perl_version set as global default"
    fi
    
    success "Perl $perl_version installed"
  else
    fail 'Invalid Perl version. Please choose from the available versions listed above.'
  fi
fi
