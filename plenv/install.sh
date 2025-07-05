#!/usr/bin/env bash
#
# Install plenv.

set -e

DOTFILES_ROOT=$(cd "$(dirname "$0")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing plenv'

if ! command -v plenv > /dev/null; then
  git clone https://github.com/tokuhirom/plenv.git ~/.plenv
  git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/

  success 'plenv installed'
else
  success 'plenv is already installed'
fi
