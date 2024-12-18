#!/usr/bin/env bash
#
# Install tfenv.

set -e

if command -v brew > /dev/null; then
  brew install tfenv
fi
