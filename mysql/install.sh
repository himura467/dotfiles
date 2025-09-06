#!/usr/bin/env bash
#
# Install MySQL.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing MySQL'

# Skip MySQL installation in CI environments
if [[ "${CI:-}" == 'true' ]]; then
  info 'Skipping MySQL installation in CI environment'
  return 0
fi

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

info "Installing MySQL@$mysql_version"
brew install mysql@"$mysql_version"

# Store the selected version for path.zsh
echo "$mysql_version" > "$(dirname "${BASH_SOURCE[0]}")/.mysql-version"
success "MySQL@$mysql_version installed"
