#!/usr/bin/env bash
#
# Install pyenv.

set -e

if command -v brew > /dev/null; then
  brew install pyenv
fi
