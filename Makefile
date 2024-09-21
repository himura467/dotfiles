.PHONY: test
test: test-dotfiles-exist test-macos test-brew

test-dotfiles-exist:
	@echo "Check if dotfiles exist..."
	@test -e ~/.zshrc && echo "OK. .zshrc exists." || (echo "FAIL. .zshrc does not exist." && exit 1)
	@test -e ~/.gitconfig && echo "OK. .gitconfig exists." || (echo "FAIL. .gitconfig does not exist." && exit 1)
	@test -e ~/.gitconfig.local && echo "OK. .gitconfig.local exists." || (echo "FAIL. .gitconfig.local does not exist." && exit 1)
	@test -e ~/.gitignore && echo "OK. .gitignore exists." || (echo "FAIL. .gitignore does not exist." && exit 1)

test-macos:
	@echo "Check if macOS settings are correct..."
	# Dock
	@test $(shell defaults read com.apple.dock tilesize) = 32 && echo "OK. Dock tilesize is correct." || (echo "FAIL. Dock tilesize is not correct." && exit 1)
	@test $(shell defaults read com.apple.dock largesize) = 96 && echo "OK. Dock largesize is correct." || (echo "FAIL. Dock largesize is not correct." && exit 1)
	@test $(shell defaults read com.apple.dock show-recents) = 0 && echo "OK. Dock show-recents is correct." || (echo "FAIL. Dock show-recents is not correct." && exit 1)
	# Finder
	@test $(shell defaults read com.apple.finder FXPreferredViewStyle) = Nlsv && echo "OK. Finder view style is correct." || (echo "FAIL. Finder view style is not correct." && exit 1)
	@test $(shell defaults read NSGlobalDomain AppleShowAllExtensions) = 1 && echo "OK. AppleShowAllExtensions is correct." || (echo "FAIL. AppleShowAllExtensions is not correct." && exit 1)
	@test $(shell defaults read com.apple.finder AppleShowAllFiles) = 1 && echo "OK. AppleShowAllFiles is correct." || (echo "FAIL. AppleShowAllFiles is not correct." && exit 1)
	@test ! $(shell ls -lOd ~/Library | grep -q hidden) && echo "OK. ~/Library is not hidden." || (echo "FAIL. ~/Library is hidden." && exit 1)
	@test $(shell defaults read com.apple.finder ShowPathbar) = 1 && echo "OK. ShowPathbar is correct." || (echo "FAIL. ShowPathbar is not correct." && exit 1)
	# Keyboard
	@test $(shell defaults read NSGlobalDomain NSAutomaticCapitalizationEnabled) = 0 && echo "OK. NSAutomaticCapitalizationEnabled is correct." || (echo "FAIL. NSAutomaticCapitalizationEnabled is not correct." && exit 1)
	@test $(shell defaults read NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled) = 0 && echo "OK. NSAutomaticPeriodSubstitutionEnabled is correct." || (echo "FAIL. NSAutomaticPeriodSubstitutionEnabled is not correct." && exit 1)
	@test $(shell defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled) = 0 && echo "OK. NSAutomaticSpellingCorrectionEnabled is correct." || (echo "FAIL. NSAutomaticSpellingCorrectionEnabled is not correct." && exit 1)
	# Trackpad
	@test $(shell defaults read -g com.apple.trackpad.scaling) = 2.5 && echo "OK. Trackpad scaling is correct." || (echo "FAIL. Trackpad scaling is not correct." && exit 1)
	@test $(shell defaults read -g com.apple.scrollwheel.scaling) = 5 && echo "OK. Scrollwheel scaling is correct." || (echo "FAIL. Scrollwheel scaling is not correct." && exit 1)

test-brew:
	@echo "Check if Homebrew is installed..."
	@test $(shell which brew) && echo "OK. Homebrew is installed." || (echo "FAIL. Homebrew is not installed." && exit 1)
