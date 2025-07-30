#!/usr/bin/env bash
#
# Bootstrap script for setting up.

set -euo pipefail

DOTFILES_ROOT=$(pwd)

source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

setup_gitconfig () {
  if ! [[ -f git/gitconfig.local.symlink ]]; then
    info 'Setting up gitconfig'

    git_credential='cache'
    if [[ "$(uname -s)" == 'Darwin' ]]; then
      git_credential='osxkeychain'
    fi

    if [[ -n "${GIT_AUTHORNAME:-}" ]]; then
      git_authorname="$GIT_AUTHORNAME"
    else
      user 'What is your github author name?'
      read -r -p '> ' -e git_authorname
    fi

    if [[ -n "${GIT_AUTHOREMAIL:-}" ]]; then
      git_authoremail="$GIT_AUTHOREMAIL"
    else
      user 'What is your github author email?'
      read -r -p '> ' -e git_authoremail
    fi

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'gitconfig set up'
  fi
}

install_dotfiles () {
  info 'Installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' -not -path '*.git*' -print0 | while IFS= read -r -d '' src; do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done
}

set_macos_defaults () {
  info 'Setting macOS defaults'

  if [[ "$(uname -s)" == 'Darwin' ]]; then
    source "$DOTFILES_ROOT/macos/set_defaults.sh"
  fi
}

run_all_installers () {
  info 'Running all installers'
  
  local installer_dirs=()
  while IFS= read -r -d '' dir; do
    [[ -f "$dir/install.sh" ]] && installer_dirs+=("$dir")
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 1 -type d -not -path '*.git*' -print0 | sort -z)
  
  for installer_dir in "${installer_dirs[@]}"; do
    local installer_name
    installer_name=$(basename "$installer_dir")
    user "Would you like to run $installer_name installer? (y/n)"
    read -r -p '> ' run_installer
    
    if [[ "$run_installer" =~ ^[Yy]$ ]]; then
      info "Running installer: $installer_dir/install.sh"
      source "$installer_dir/install.sh"
      
      if [[ -f "$installer_dir/path.zsh" ]]; then
        # Skip zsh-specific path.zsh files that contain syntax incompatible with bash
        if [[ "$installer_name" == 'direnv' || "$installer_name" == 'gcloud' || "$installer_name" == 'sheldon' ]]; then
          info "Skipping $installer_name path.zsh due to bash/zsh compatibility issues"
        else
          info "Sourcing path configuration: $installer_dir/path.zsh"
          # shellcheck source=/dev/null
          source "$installer_dir/path.zsh"
        fi
      fi
    else
      info "Skipping $installer_name installer"
    fi
  done
}

setup_gitconfig
install_dotfiles
set_macos_defaults
run_all_installers

success 'All installed'
