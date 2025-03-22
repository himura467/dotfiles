#!/usr/bin/env bash
#
# Bootstrap script for setting up.

set -e

DOTFILES_ROOT=$(pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

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
      user ' - What is your github author name?'
      read -p '>' -e git_authorname
    fi

    if [[ -n "$GIT_AUTHOREMAIL" ]]; then
      git_authoremail="$GIT_AUTHOREMAIL"
    else
      user ' - What is your github author email?'
      read -p '>' -e git_authoremail
    fi

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'gitconfig set up'
  fi
}


link_file () {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [[ -f "$dst" || -d "$dst" || -L "$dst" ]]; then
    if [[ "$overwrite_all" == 'false' && "$backup_all" == 'false' && "$skip_all" == 'false' ]]; then
      local current_src="$(readlink $dst)"

      if [[ "$current_src" == "$src" ]]; then
        skip=true;
      else
        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -p '>' -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac
      fi
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [[ "$overwrite" == 'true' ]]; then
      rm -rf "$dst"
      success "Removed $dst"
    fi

    if [[ "$backup" == 'true' ]]; then
      mv "$dst" "${dst}.backup"
      success "Moved $dst to ${dst}.backup"
    fi

    if [[ "$skip" == 'true' ]]; then
      success "Skipped $src"
    fi
  fi

  if [[ "$skip" != 'true' ]]; then
    ln -s "$1" "$2"
    success "Linked $1 to $2"
  fi
}

install_dotfiles () {
  info 'Installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' -not -path '*.git*'); do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done
}

set_macos_defaults () {
  info 'Setting macOS defaults'

  if [[ "$(uname -s)" == 'Darwin' ]]; then
    $DOTFILES_ROOT/macos/set-defaults.sh
  fi
}

set_homebrew () {
  if ! command -v brew > /dev/null; then
    $DOTFILES_ROOT/homebrew/install.sh

    source $DOTFILES_ROOT/homebrew/path.zsh
  else
    $DOTFILES_ROOT/homebrew/upgrade.sh
  fi
}

set_neovim () {
  if ! command -v nvim > /dev/null; then
    $DOTFILES_ROOT/neovim/install.sh
  fi
}

setup_gitconfig
install_dotfiles
set_macos_defaults
set_homebrew
set_neovim

echo '  All installed'
