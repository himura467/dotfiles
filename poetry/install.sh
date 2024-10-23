#!/usr/bin/env bash
#
# Install Poetry.

set -e

if test ! $(which poetry); then
  echo '  Installing Poetry...'

  if test $(which python); then
    curl -sSL https://install.python-poetry.org | python -
  else
    echo '  Error: Python not found. Python is required to install Poetry.'
  fi
fi
