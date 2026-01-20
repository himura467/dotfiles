#!/usr/bin/env bash
#
# Bootstrap script for setting up.

set -euo pipefail

DOTFILES_ROOT=$(pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

set_macos_defaults () {
  info 'Setting macOS defaults'
  if [[ "$(uname -s)" == 'Darwin' ]]; then
    source "$DOTFILES_ROOT/macos/set_defaults.sh"
  fi
}

run_all_setups () {
  info 'Running all setups'
  local setup_dirs=()
  while IFS= read -r -d '' dir; do
    [[ -f "$dir/setup.sh" ]] && setup_dirs+=("$dir")
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 1 -type d -not -path '*.git*' -print0 | sort -z)
  for setup_dir in "${setup_dirs[@]}"; do
    local setup_name run_setup
    setup_name=$(basename "$setup_dir")
    user "Would you like to run $setup_name setup? (y/n)"
    read -r -p '> ' run_setup
    if [[ "$run_setup" =~ ^[Yy]$ ]]; then
      info "Running setup: $setup_dir/setup.sh"
      # shellcheck source=/dev/null
      source "$setup_dir/setup.sh"
    else
      info "Skipping $setup_name setup"
    fi
  done
}

run_all_installers () {
  info 'Running all installers'
  local installer_dirs=()
  while IFS= read -r -d '' dir; do
    [[ -f "$dir/install.sh" ]] && installer_dirs+=("$dir")
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 1 -type d -not -path '*.git*' -print0 | sort -z)
  for installer_dir in "${installer_dirs[@]}"; do
    local installer_name run_installer
    installer_name=$(basename "$installer_dir")
    user "Would you like to run $installer_name installer? (y/n)"
    read -r -p '> ' run_installer
    if [[ "$run_installer" =~ ^[Yy]$ ]]; then
      info "Running installer: $installer_dir/install.sh"
      # shellcheck source=/dev/null
      source "$installer_dir/install.sh"
      if [[ -f "$installer_dir/path.zsh" ]]; then
        # Skip zsh-specific path.zsh files that contain syntax incompatible with bash
        if [[ "$installer_name" == 'direnv' || "$installer_name" == 'gcloud' || "$installer_name" == 'sheldon' ]]; then
          info "Skipping $installer_name path.zsh due to bash/zsh compatibility issues"
        else
          info "Sourcing path configuration: $installer_dir/path.zsh"
          # shellcheck source=/dev/null
          if ! source "$installer_dir/path.zsh" 2 > /dev/null; then
            warn "Failed to source $installer_dir/path.zsh, continuing..."
          fi
        fi
      fi
    else
      info "Skipping $installer_name installer"
    fi
  done
}

set_macos_defaults
run_all_setups
run_all_installers

success 'All installed'
