#!/usr/bin/env bash
#
# Set macOS defaults.

set -e

# Dock
## Set the icon size of Dock items to 32 pixels.
defaults write com.apple.dock tilesize -int 32

## Set the large size of Dock items to 96 pixels.
defaults write com.apple.dock largesize -int 96

## Don't show recent apps in Dock.
defaults write com.apple.dock show-recents -bool false

# Finder
## Always open everything in Finder's list view.
defaults write com.apple.finder FXPreferredViewStyle Nlsv

## Show all file extensions in Finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

## Show hidden files in Finder.
defaults write com.apple.finder AppleShowAllFiles -bool true

## Show the ~/Library folder.
chflags nohidden ~/Library

## Show path bar in Finder.
defaults write com.apple.finder ShowPathbar -bool true

## Set the default location for new Finder windows to the home folder.
defaults write com.apple.finder NewWindowTarget PfHm

# Keyboard
## Disable press-and-hold for keys in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

## Set the key repeat rate to fast.
defaults write NSGlobalDomain KeyRepeat -int 1

## Set the delay until key repeat starts to short.
defaults write NSGlobalDomain InitialKeyRepeat -int 15

## Disable automatic capitalization.
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

## Disable automatic period substitution.
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

## Disable automatic spelling correction.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Trackpad
## Set tracking speed to 2.5.
defaults write -g com.apple.trackpad.scaling 2.5

## Set scroll speed to 5.
defaults write -g com.apple.scrollwheel.scaling 5
