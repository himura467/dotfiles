#!/usr/bin/env bash
#
# Install Google Cloud SDK.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Google Cloud SDK'

if ! command -v gcloud > /dev/null; then
  if command -v brew > /dev/null; then
    brew install --cask google-cloud-sdk

    success 'Google Cloud SDK installed'
  else
    fail 'Homebrew not found. Homebrew is required to install Google Cloud SDK.'
  fi
else
  success 'Google Cloud SDK is already installed'
fi
