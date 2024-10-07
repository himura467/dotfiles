#!/usr/bin/env bash
#
# Install pyenv.

set -e

if test ! $(which pyenv); then
  echo '  Installing pyenv...'

  brew install pyenv
fi
