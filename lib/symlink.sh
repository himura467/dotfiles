#!/usr/bin/env bash
#
# Symlink script for setting up dotfiles.

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
