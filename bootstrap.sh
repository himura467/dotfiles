#!/usr/bin/env bash
#
# Bootstrap script for setting up.

set -e

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

    if [[ -n "$GIT_AUTHORNAME" ]]; then
      git_authorname="$GIT_AUTHORNAME"
    else
      user 'What is your github author name?'
      read -r -p '> ' -e git_authorname
    fi

    if [[ -n "$GIT_AUTHOREMAIL" ]]; then
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
    "$DOTFILES_ROOT"/macos/set_defaults.sh
  fi
}

run_all_installers () {
  info 'Running all installers'
  
  local installers=()
  while IFS= read -r -d '' installer; do
    installers+=("$installer")
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 2 -name 'install.sh' -not -path '*.git*' -type f -print0 | sort -z)
  
  for installer in "${installers[@]}"; do
    local installer_name=$(basename "$(dirname "$installer")")
    user "Would you like to run $installer_name installer? (y/n)"
    read -r -p '> ' run_installer
    
    if [[ "$run_installer" =~ ^[Yy]$ ]]; then
      info "Running installer: $installer"
      "$installer"
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
