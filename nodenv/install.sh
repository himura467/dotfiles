#!/usr/bin/env bash
#
# Install nodenv.

set -e

if test ! $(which nodenv); then
  echo '  Installing nodenv...'

  brew install nodenv
fi
