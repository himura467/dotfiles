alias ga="git add -A"
alias gb="git branch"
alias gc="git commit"
alias gco="git checkout"
# Remove "+" and "-" from start of diff lines; just rely upon color.
alias gd="git diff --color | sed 's/^\([^-+ ]*\)[-+ ]/\\1/' | less -r"
alias gs="git status -sb"
