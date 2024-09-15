#!/usr/bin/env bash
#
# Dotfiles management.

set -e

$HOME/.dotfiles/macos/set-defaults.sh

$HOME/.dotfiles/homebrew/install.sh
$HOME/.dotfiles/homebrew/upgrade.sh
