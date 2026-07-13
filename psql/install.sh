#!/usr/bin/env bash
#
# Install PostgreSQL.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing PostgreSQL'
if ! command -v brew > /dev/null; then
  user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
  read -r -p '> ' install_brew
  if [[ "$install_brew" =~ ^[Yy]$ ]]; then
    source "$DOTFILES_ROOT/homebrew/install.sh"
    source "$DOTFILES_ROOT/homebrew/path.zsh"
  else
    fail 'Homebrew is required to install PostgreSQL.'
    exit 1
  fi
fi
# Get available PostgreSQL versions
available_versions=$(brew search postgresql@ | grep -E '^postgresql@[0-9.]+$' | sed 's/postgresql@//')
user 'Which PostgreSQL version would you like to install?'
info 'Available versions:'
info_list "$available_versions"
read -r -p '> ' psql_version
info "Installing PostgreSQL@$psql_version"
brew install postgresql@"$psql_version"
# Store the selected version for path.zsh
echo "$psql_version" > "$(dirname "${BASH_SOURCE[0]}")/.psql-version"
success "PostgreSQL@$psql_version installed"
