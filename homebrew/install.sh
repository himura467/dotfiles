#!/usr/bin/env bash
#
# Install Homebrew.

set -e

if [[ "$(uname -s)" == 'Darwin' ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
