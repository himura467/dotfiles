alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add --patch'
alias gb='git branch'
alias gbd='git branch --delete --force'
alias gbm='git branch --move'
alias gc='git commit'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gcm='git commit --message'
alias gcle='git clean -d --force'
alias gclo='git clone'
alias gco='git checkout'
alias gcob='git checkout -b'
# Remove "+" and "-" from start of diff lines; just rely upon color.
alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/" | less -r'
alias gf='git fetch'
alias gfa='git fetch --all'
alias gl='git log --graph --pretty=format:"%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'
alias gpl='git pull'
alias gps='git push'
alias grb='git rebase'
alias grs='git reset'
alias gs='git status --short --branch'
