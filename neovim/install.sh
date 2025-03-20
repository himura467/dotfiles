#!/usr/bin/env bash
#
# Install Neovim.

set -e

DOTFILES_ROOT=$(pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Neovim'

if command -v brew > /dev/null; then
	brew install neovim

	# Install dependencies.
	brew install ripgrep

	git clone https://github.com/dam9000/kickstart-modular.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

  success 'Neovim installed'
else
	fail 'Homebrew not found. Homebrew is required to install Neovim.'
fi
