#!/usr/bin/env bash
#
# Setup Git.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"
source "$DOTFILES_ROOT/lib/symlink.sh"

info 'Setting up Git'
if ! [[ -f "$DOTFILES_ROOT/git/gitconfig.local.symlink" ]]; then
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
  sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" "$DOTFILES_ROOT/git/gitconfig.local.symlink.example" > "$DOTFILES_ROOT/git/gitconfig.local.symlink"
fi
overwrite_all=false backup_all=false skip_all=false
link_file "$DOTFILES_ROOT/git/gitconfig.symlink" "$HOME/.gitconfig"
link_file "$DOTFILES_ROOT/git/gitconfig.local.symlink" "$HOME/.gitconfig.local"
link_file "$DOTFILES_ROOT/git/gitignore.symlink" "$HOME/.gitignore"
success 'Git set up'
