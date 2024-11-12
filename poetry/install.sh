#!/usr/bin/env bash
#
# Install Poetry.

set -e

if ! command -v poetry > /dev/null; then
  if command -v python > /dev/null; then
    curl -sSL https://install.python-poetry.org | python -
  else
    echo '  Error: Python not found. Python is required to install Poetry.'
  fi
fi
