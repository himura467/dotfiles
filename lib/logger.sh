#!/usr/bin/env bash
#
# The logger methods.

info () {
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

info_list () {
  echo "$1" | while read -r line; do
    printf "%s\n" "$line"
  done
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
  echo ''
  exit
}
