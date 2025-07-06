.PHONY: test
test: test-dotfiles-exist test-macos test-git ci-debug test-installers

ci-debug:
	@echo 'Debug information for plenv installation...'
	@echo 'Current PATH:'
	@echo "$$PATH"
	@echo 'Home directory:'
	@echo "$$HOME"
	@echo 'Check if .plenv directory exists:'
	@ls -la "$$HOME/.plenv" 2>/dev/null || echo "Directory $$HOME/.plenv does not exist"
	@echo 'Check if plenv binary exists:'
	@ls -la "$$HOME/.plenv/bin/plenv" 2>/dev/null || echo "Binary $$HOME/.plenv/bin/plenv does not exist"
	@echo 'Check if plenv is in PATH:'
	@command -v plenv && echo "plenv found in PATH" || echo "plenv NOT found in PATH"
	@echo 'Try to execute plenv directly:'
	@$$HOME/.plenv/bin/plenv --version 2>/dev/null || echo "Cannot execute plenv directly"
	@echo 'Check shell:'
	@echo "SHELL: $$SHELL"
	@echo 'Check if path.zsh was sourced correctly:'
	@[[ -f "$$HOME/.dotfiles/plenv/path.zsh" ]] && echo "path.zsh exists" || echo "path.zsh missing"

test-dotfiles-exist:
	@echo 'Check if dotfiles exist...'
	@[[ -e ~/.zshrc ]] && echo 'OK. .zshrc exists.' || (echo 'FAIL. .zshrc does not exist.' && exit 1)
	@[[ -e ~/.gitconfig ]] && echo 'OK. .gitconfig exists.' || (echo 'FAIL. .gitconfig does not exist.' && exit 1)
	@[[ -e ~/.gitconfig.local ]] && echo 'OK. .gitconfig.local exists.' || (echo 'FAIL. .gitconfig.local does not exist.' && exit 1)
	@[[ -e ~/.gitignore ]] && echo 'OK. .gitignore exists.' || (echo 'FAIL. .gitignore does not exist.' && exit 1)

test-macos:
	@echo 'Check if macOS settings are correct...'
	# Desktop Services
	@[[ "$(shell defaults read com.apple.desktopservices DSDontWriteNetworkStores)" = 1 ]] && echo 'OK. .DS_Store files on network volumes are disabled.' || (echo 'FAIL. .DS_Store files on network volumes are not disabled.' && exit 1)
	@[[ "$(shell defaults read com.apple.desktopservices DSDontWriteUSBStores)" = 1 ]] && echo 'OK. .DS_Store files on USB volumes are disabled.' || (echo 'FAIL. .DS_Store files on USB volumes are not disabled.' && exit 1)
	# Dock
	@[[ "$(shell defaults read com.apple.dock tilesize)" = 32 ]] && echo 'OK. Dock tilesize is correct.' || (echo 'FAIL. Dock tilesize is not correct.' && exit 1)
	@[[ "$(shell defaults read com.apple.dock largesize)" = 96 ]] && echo 'OK. Dock largesize is correct.' || (echo 'FAIL. Dock largesize is not correct.' && exit 1)
	@[[ "$(shell defaults read com.apple.dock show-recents)" = 0 ]] && echo 'OK. Dock show-recents is correct.' || (echo 'FAIL. Dock show-recents is not correct.' && exit 1)
	# Finder
	@[[ "$(shell defaults read com.apple.finder FXPreferredViewStyle)" = Nlsv ]] && echo 'OK. Finder view style is correct.' || (echo 'FAIL. Finder view style is not correct.' && exit 1)
	@[[ "$(shell defaults read NSGlobalDomain AppleShowAllExtensions)" = 1 ]] && echo 'OK. AppleShowAllExtensions is correct.' || (echo 'FAIL. AppleShowAllExtensions is not correct.' && exit 1)
	@[[ "$(shell defaults read com.apple.finder AppleShowAllFiles)" = 1 ]] && echo 'OK. AppleShowAllFiles is correct.' || (echo 'FAIL. AppleShowAllFiles is not correct.' && exit 1)
	@! [[ "$(shell ls -lOd ~/Library | grep -q hidden)" ]] && echo 'OK. ~/Library is not hidden.' || (echo 'FAIL. ~/Library is hidden.' && exit 1)
	@[[ "$(shell defaults read com.apple.finder ShowPathbar)" = 1 ]] && echo 'OK. ShowPathbar is correct.' || (echo 'FAIL. ShowPathbar is not correct.' && exit 1)
	@[[ "$(shell defaults read com.apple.finder NewWindowTarget)" = PfHm ]] && echo 'OK. NewWindowTarget is correct.' || (echo 'FAIL. NewWindowTarget is not correct.' && exit 1)
	# Keyboard
	@[[ "$(shell defaults read -g ApplePressAndHoldEnabled)" = 0 ]] && echo 'OK. ApplePressAndHoldEnabled is correct.' || (echo 'FAIL. ApplePressAndHoldEnabled is not correct.' && exit 1)
	@[[ "$(shell defaults read NSGlobalDomain KeyRepeat)" = 1 ]] && echo 'OK. KeyRepeat is correct.' || (echo 'FAIL. KeyRepeat is not correct.' && exit 1)
	@[[ "$(shell defaults read NSGlobalDomain InitialKeyRepeat)" = 15 ]] && echo 'OK. InitialKeyRepeat is correct.' || (echo 'FAIL. InitialKeyRepeat is not correct.' && exit 1)
	@[[ "$(shell defaults read NSGlobalDomain NSAutomaticCapitalizationEnabled)" = 0 ]] && echo 'OK. NSAutomaticCapitalizationEnabled is correct.' || (echo 'FAIL. NSAutomaticCapitalizationEnabled is not correct.' && exit 1)
	@[[ "$(shell defaults read NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled)" = 0 ]] && echo 'OK. NSAutomaticPeriodSubstitutionEnabled is correct.' || (echo 'FAIL. NSAutomaticPeriodSubstitutionEnabled is not correct.' && exit 1)
	@[[ "$(shell defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled)" = 0 ]] && echo 'OK. NSAutomaticSpellingCorrectionEnabled is correct.' || (echo 'FAIL. NSAutomaticSpellingCorrectionEnabled is not correct.' && exit 1)
	# Screenshots
	@[[ "$(shell defaults read com.apple.screencapture location)" = ~/Downloads ]] && echo 'OK. Screenshot location is correct.' || (echo 'FAIL. Screenshot location is not correct.' && exit 1)
	@[[ "$(shell defaults read com.apple.screencapture name)" = screenshot ]] && echo 'OK. Screenshot name is correct.' || (echo 'FAIL. Screenshot name is not correct.' && exit 1)
	@[[ "$(shell defaults read com.apple.screencapture disable-shadow)" = 1 ]] && echo 'OK. Screenshot shadow is disabled.' || (echo 'FAIL. Screenshot shadow is not disabled.' && exit 1)
	@[[ "$(shell defaults read com.apple.screencapture show-thumbnail)" = 0 ]] && echo 'OK. Screenshot thumbnail is disabled.' || (echo 'FAIL. Screenshot thumbnail is not disabled.' && exit 1)
	# Trackpad
	@[[ "$(shell defaults read -g com.apple.trackpad.scaling)" = 2.5 ]] && echo 'OK. Trackpad scaling is correct.' || (echo 'FAIL. Trackpad scaling is not correct.' && exit 1)
	@[[ "$(shell defaults read -g com.apple.scrollwheel.scaling)" = 5 ]] && echo 'OK. Scrollwheel scaling is correct.' || (echo 'FAIL. Scrollwheel scaling is not correct.' && exit 1)

test-git:
	@echo 'Check if git is set up correctly...'
	@[[ "$(shell git config --get user.name)" = "$(GIT_AUTHORNAME)" ]] && echo 'OK. Git user.name is correct.' || (echo 'FAIL. Git user.name is not correct.' && exit 1)
	@[[ "$(shell git config --get user.email)" = "$(GIT_AUTHOREMAIL)" ]] && echo 'OK. Git user.email is correct.' || (echo 'FAIL. Git user.email is not correct.' && exit 1)
	@[[ "$(shell git config --get credential.helper)" = 'osxkeychain' ]] && echo 'OK. Git credential.helper is set to osxkeychain.' || (echo 'FAIL. Git credential.helper is not set to osxkeychain.' && exit 1)

test-installers:
	@echo 'Check if tools installed by run_all_installers are available...'
	# Core development tools
	@command -v op > /dev/null && echo 'OK. 1password-cli is installed.' || (echo 'FAIL. 1password-cli is not installed.' && exit 1)
	@command -v aws > /dev/null && echo 'OK. aws-cli is installed.' || (echo 'FAIL. aws-cli is not installed.' && exit 1)
	# Claude Code is commented out because it requires interactive approval (pnpm approve-builds -g)
	# which cannot be handled by the `yes` command in CI environments
	# @command -v claude > /dev/null && echo 'OK. claude-code is installed.' || (echo 'FAIL. claude-code is not installed.' && exit 1)
	@command -v direnv > /dev/null && echo 'OK. direnv is installed.' || (echo 'FAIL. direnv is not installed.' && exit 1)
	@command -v docker > /dev/null && echo 'OK. docker is installed.' || (echo 'FAIL. docker is not installed.' && exit 1)
	@command -v gcloud > /dev/null && echo 'OK. gcloud is installed.' || (echo 'FAIL. gcloud is not installed.' && exit 1)
	@command -v ghostty > /dev/null && echo 'OK. ghostty is installed.' || (echo 'FAIL. ghostty is not installed.' && exit 1)
	@command -v go > /dev/null && echo 'OK. go is installed.' || (echo 'FAIL. go is not installed.' && exit 1)
	@command -v brew > /dev/null && echo 'OK. homebrew is installed.' || (echo 'FAIL. homebrew is not installed.' && exit 1)
	# MySQL is commented out because the installer requires interactive version selection
	# which cannot be handled by the `yes` command in CI environments
	# @command -v mysql > /dev/null && echo 'OK. mysql is installed.' || (echo 'FAIL. mysql is not installed.' && exit 1)
	@command -v nvim > /dev/null && echo 'OK. neovim is installed.' || (echo 'FAIL. neovim is not installed.' && exit 1)
	@command -v nodenv > /dev/null && echo 'OK. nodenv is installed.' || (echo 'FAIL. nodenv is not installed.' && exit 1)
	@(command -v plenv > /dev/null || [[ -x "$$HOME/.plenv/bin/plenv" ]]) && echo 'OK. plenv is installed.' || (echo 'FAIL. plenv is not installed.' && exit 1)
	@command -v pnpm > /dev/null && echo 'OK. pnpm is installed.' || (echo 'FAIL. pnpm is not installed.' && exit 1)
	@command -v poetry > /dev/null && echo 'OK. poetry is installed.' || (echo 'FAIL. poetry is not installed.' && exit 1)
	@command -v pyenv > /dev/null && echo 'OK. pyenv is installed.' || (echo 'FAIL. pyenv is not installed.' && exit 1)
	@command -v sheldon > /dev/null && echo 'OK. sheldon is installed.' || (echo 'FAIL. sheldon is not installed.' && exit 1)
	@command -v tfenv > /dev/null && echo 'OK. tfenv is installed.' || (echo 'FAIL. tfenv is not installed.' && exit 1)
	# Applications
	@ls /Applications/Docker.app > /dev/null 2>&1 && echo 'OK. Docker app is installed.' || (echo 'FAIL. Docker app is not installed.' && exit 1)
	@ls /Applications/Ghostty.app > /dev/null 2>&1 && echo 'OK. Ghostty app is installed.' || (echo 'FAIL. Ghostty app is not installed.' && exit 1)
	@ls /Applications/Raycast.app > /dev/null 2>&1 && echo 'OK. Raycast is installed.' || (echo 'FAIL. Raycast is not installed.' && exit 1)
