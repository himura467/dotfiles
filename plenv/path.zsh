[[ -d $HOME/.plenv/bin ]] && export PATH="$HOME/.plenv/bin:$PATH"
command -v plenv > /dev/null && eval "$(plenv init -)"
