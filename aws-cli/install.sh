#!/usr/bin/env bash
#
# Install AWS CLI.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing AWS CLI'

if ! command -v aws > /dev/null; then
  curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
  sudo installer -pkg AWSCLIV2.pkg -target /
  rm -f AWSCLIV2.pkg

  success 'AWS CLI installed'
else
  success 'AWS CLI is already installed'
fi
