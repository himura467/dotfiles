#!/usr/bin/env bash
#
# Install nodenv.

set -e

if ! command -v nodenv > /dev/null; then
  echo '  Installing nodenv...'

  brew install nodenv
fi
