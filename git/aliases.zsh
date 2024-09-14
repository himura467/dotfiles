alias ga="git add -A"
alias gb="git branch"
alias gc="git commit"
alias gco="git checkout"
# Remove "+" and "-" from start of diff lines; just rely upon color.
alias gd="git diff --color | sed 's/^\([^-+ ]*\)[-+ ]/\\1/' | less -r"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp="git push origin HEAD"
alias gs="git status -sb"
