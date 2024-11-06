#!/usr/bin/env bash
#
# Install plenv.

set -e

if test ! $(which plenv); then
  echo '  Installing plenv...'

  git clone https://github.com/tokuhirom/plenv.git ~/.plenv
  git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
fi
