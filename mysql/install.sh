#!/usr/bin/env bash
#
# Install MySQL.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing MySQL'

if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install MySQL.'
  fi
fi

# Get available MySQL versions
available_versions=$(brew search mysql@ | grep -E '^mysql@[0-9.]+$' | sed 's/mysql@//')

user 'Which MySQL version would you like to install?'
info 'Available versions:'
info_list "$available_versions"
read -r -p '> ' mysql_version

if echo "$available_versions" | grep -q "^$mysql_version$"; then
  info "Installing MySQL@$mysql_version"
  brew install mysql@"$mysql_version"
  
  # Store the selected version for path.zsh
  echo "$mysql_version" > "$(dirname "$0")/.mysql-version"
  success "MySQL@$mysql_version installed"
else
  fail 'Invalid MySQL version. Please choose from the available versions listed above.'
fi
