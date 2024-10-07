#!/usr/bin/env bash
#
# Upgrade Homebrew.

set -e

echo '  Upgrading Homebrew...'
brew update
brew upgrade
brew upgrade --cask
