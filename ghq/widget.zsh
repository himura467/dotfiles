# fzf ghq widget for navigating to ghq-managed repositories
if command -v ghq > /dev/null && command -v fzf > /dev/null; then
  fzf-ghq-widget() {
    local repo=$(ghq list | fzf --reverse --query "$LBUFFER")
    if [[ -n "$repo" ]]; then
      repo=$(ghq list --full-path --exact "$repo")
      BUFFER="cd ${(q)repo}"
      zle accept-line
    fi
    zle reset-prompt
  }
  zle -N fzf-ghq-widget
  bindkey '\eg' fzf-ghq-widget
fi
