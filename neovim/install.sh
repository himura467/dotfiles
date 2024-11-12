#!/usr/bin/env bash
#
# Install Neovim.

set -e

brew install neovim

# Install dependencies.
brew install ripgrep

git clone https://github.com/dam9000/kickstart-modular.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
