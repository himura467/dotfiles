#!/usr/bin/env bash
#
# Install MySQL.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing MySQL'

if command -v brew > /dev/null; then
  # Get available MySQL versions
  available_versions=$(brew search mysql@ | grep -E '^mysql@[0-9.]+$' | sed 's/mysql@//')

  user "Which MySQL version would you like to install?\n\
Available versions:\n$available_versions"
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
else
  fail 'Homebrew not found. Homebrew is required to install MySQL.'
fi
