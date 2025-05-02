#!/usr/bin/env bash
#
# Update Ghostty theme randomly.

set -e

DOTFILES_ROOT=$(cd $(dirname $0)/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Updating Ghostty theme'

# Get a random theme from available themes
new_theme=$(ghostty +list-themes | sort -R | head -n 1 | sed 's/ (.*)$//')
if [ -z "$new_theme" ]; then
  fail 'Failed to get theme list from Ghostty'
fi

# Config file path
config_file="$DOTFILES_ROOT/ghostty/config"

# Replace theme line if it exists, otherwise append it
if grep -q "^theme" "$config_file"; then
  if sed -i '' "s/^theme.*$/theme = $new_theme/" "$config_file"; then
    success "Theme updated to: $new_theme"
  else
    fail "Failed to update theme in config file"
  fi
else
  if echo "theme = $new_theme" >> "$config_file"; then
    success "Theme added: $new_theme"
  else
    fail "Failed to add theme to config file"
  fi
fi
