#!/usr/bin/env bash
#
# Install plenv.

set -e

if ! command -v plenv > /dev/null; then
  echo '  Installing plenv...'

  git clone https://github.com/tokuhirom/plenv.git ~/.plenv
  git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
fi
