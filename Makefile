.PHONY: test
test: test-dotfiles-exist test-macos test-git test-brew test-neovim

test-dotfiles-exist:
	@echo 'Check if dotfiles exist...'
	@[[ -e ~/.zshrc ]] && echo 'OK. .zshrc exists.' || (echo 'FAIL. .zshrc does not exist.' && exit 1)
	@[[ -e ~/.gitconfig ]] && echo 'OK. .gitconfig exists.' || (echo 'FAIL. .gitconfig does not exist.' && exit 1)
	@[[ -e ~/.gitconfig.local ]] && echo 'OK. .gitconfig.local exists.' || (echo 'FAIL. .gitconfig.local does not exist.' && exit 1)
	@[[ -e ~/.gitignore ]] && echo 'OK. .gitignore exists.' || (echo 'FAIL. .gitignore does not exist.' && exit 1)

test-macos:
	@echo 'Check if macOS settings are correct...'
	# Desktop Services
	@defaults write com.apple.desktopservices DSDontWriteNetworkStores > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.desktopservices DSDontWriteNetworkStores)" = 1 ]] && echo 'OK. .DS_Store files on network volumes are disabled.' || (echo 'FAIL. .DS_Store files on network volumes are not disabled.' && exit 1)) || \
	echo 'INFO: .DS_Store files on network volumes are not set. Skipping test.'
	@defaults write com.apple.desktopservices DSDontWriteUSBStores > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.desktopservices DSDontWriteUSBStores)" = 1 ]] && echo 'OK. .DS_Store files on USB volumes are disabled.' || (echo 'FAIL. .DS_Store files on USB volumes are not disabled.' && exit 1)) || \
	echo 'INFO: .DS_Store files on USB volumes are not set. Skipping test.'
	# Dock
	@defaults read com.apple.dock tilesize > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.dock tilesize)" = 32 ]] && echo 'OK. Dock tilesize is correct.' || (echo 'FAIL. Dock tilesize is not correct.' && exit 1)) || \
	echo 'INFO: Dock tilesize is not set. Skipping test.'
	@defaults read com.apple.dock largesize > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.dock largesize)" = 96 ]] && echo 'OK. Dock largesize is correct.' || (echo 'FAIL. Dock largesize is not correct.' && exit 1)) || \
	echo 'INFO: Dock largesize is not set. Skipping test.'
	@defaults read com.apple.dock show-recents > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.dock show-recents)" = 0 ]] && echo 'OK. Dock show-recents is correct.' || (echo 'FAIL. Dock show-recents is not correct.' && exit 1)) || \
	echo 'INFO: Dock show-recents is not set. Skipping test.'
	# Finder
	@defaults read com.apple.finder FXPreferredViewStyle > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.finder FXPreferredViewStyle)" = Nlsv ]] && echo 'OK. Finder view style is correct.' || (echo 'FAIL. Finder view style is not correct.' && exit 1)) || \
	echo 'INFO: Finder view style is not set. Skipping test.'
	@defaults read NSGlobalDomain AppleShowAllExtensions > /dev/null 2>&1 && \
	([[ "$(shell defaults read NSGlobalDomain AppleShowAllExtensions)" = 1 ]] && echo 'OK. AppleShowAllExtensions is correct.' || (echo 'FAIL. AppleShowAllExtensions is not correct.' && exit 1)) || \
	echo 'INFO: AppleShowAllExtensions is not set. Skipping test.'
	@defaults read com.apple.finder AppleShowAllFiles > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.finder AppleShowAllFiles)" = 1 ]] && echo 'OK. AppleShowAllFiles is correct.' || (echo 'FAIL. AppleShowAllFiles is not correct.' && exit 1)) || \
	echo 'INFO: AppleShowAllFiles is not set. Skipping test.'
	@! [[ "$(shell ls -lOd ~/Library | grep -q hidden)" ]] && echo 'OK. ~/Library is not hidden.' || (echo 'FAIL. ~/Library is hidden.' && exit 1)
	@defaults read com.apple.finder ShowPathbar > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.finder ShowPathbar)" = 1 ]] && echo 'OK. ShowPathbar is correct.' || (echo 'FAIL. ShowPathbar is not correct.' && exit 1)) || \
	echo 'INFO: ShowPathbar is not set. Skipping test.'
	@defaults read com.apple.finder NewWindowTarget > /dev/null 2>&1 && \
	([[ "$(shell defaults read com.apple.finder NewWindowTarget)" = PfHm ]] && echo 'OK. NewWindowTarget is correct.' || (echo 'FAIL. NewWindowTarget is not correct.' && exit 1)) || \
	echo 'INFO: NewWindowTarget is not set. Skipping test.'
	# Keyboard
	@defaults read NSGlobalDomain NSAutomaticCapitalizationEnabled > /dev/null 2>&1 && \
	([[ "$(shell defaults read NSGlobalDomain NSAutomaticCapitalizationEnabled)" = 0 ]] && echo 'OK. NSAutomaticCapitalizationEnabled is correct.' || (echo 'FAIL. NSAutomaticCapitalizationEnabled is not correct.' && exit 1)) || \
	echo 'INFO: NSAutomaticCapitalizationEnabled is not set. Skipping test.'
	@defaults read NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled > /dev/null 2>&1 && \
	([[ "$(shell defaults read NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled)" = 0 ]] && echo 'OK. NSAutomaticPeriodSubstitutionEnabled is correct.' || (echo 'FAIL. NSAutomaticPeriodSubstitutionEnabled is not correct.' && exit 1)) || \
	echo 'INFO: NSAutomaticPeriodSubstitutionEnabled is not set. Skipping test.'
	@defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled > /dev/null 2>&1 && \
	([[ "$(shell defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled)" = 0 ]] && echo 'OK. NSAutomaticSpellingCorrectionEnabled is correct.' || (echo 'FAIL. NSAutomaticSpellingCorrectionEnabled is not correct.' && exit 1)) || \
	echo 'INFO: NSAutomaticSpellingCorrectionEnabled is not set. Skipping test.'
	# Trackpad
	@defaults read -g com.apple.trackpad.scaling > /dev/null 2>&1 && \
	([[ "$(shell defaults read -g com.apple.trackpad.scaling)" = 2.5 ]] && echo 'OK. Trackpad scaling is correct.' || (echo 'FAIL. Trackpad scaling is not correct.' && exit 1)) || \
	echo 'INFO: Trackpad scaling is not set. Skipping test.'
	@defaults read -g com.apple.scrollwheel.scaling > /dev/null 2>&1 && \
	([[ "$(shell defaults read -g com.apple.scrollwheel.scaling)" = 5 ]] && echo 'OK. Scrollwheel scaling is correct.' || (echo 'FAIL. Scrollwheel scaling is not correct.' && exit 1)) || \
	echo 'INFO: Scrollwheel scaling is not set. Skipping test.'

test-git:
	@echo 'Check if git is set up correctly...'
	@[[ "$(shell git config --get user.name)" = "$(GIT_AUTHORNAME)" ]] && echo 'OK. Git user.name is correct.' || (echo 'FAIL. Git user.name is not correct.' && exit 1)
	@[[ "$(shell git config --get user.email)" = "$(GIT_AUTHOREMAIL)" ]] && echo 'OK. Git user.email is correct.' || (echo 'FAIL. Git user.email is not correct.' && exit 1)

test-brew:
	@echo 'Check if Homebrew is installed...'
	@command -v brew > /dev/null && echo 'OK. Homebrew is installed.' || (echo 'FAIL. Homebrew is not installed.' && exit 1)

test-neovim:
	@echo 'Check if Neovim is installed...'
	@command -v nvim > /dev/null && echo 'OK. Neovim is installed.' || (echo 'FAIL. Neovim is not installed.' && exit 1)
