#!/usr/bin/env bash
#
# Dotfiles management.

set -e

$HOME/.dotfiles/macos/set-defaults.sh

$HOME/.dotfiles/homebrew/install.sh
eval "$(/opt/homebrew/bin/brew shellenv)"
$HOME/.dotfiles/homebrew/upgrade.sh
