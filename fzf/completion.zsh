if command -v fzf > /dev/null; then
  source <(fzf --zsh)
  # Rebind cd widget to Hyper+C (Cmd+Ctrl+Opt+Shift+C)
  bindkey -r '\ec'
  bindkey '^[^C' fzf-cd-widget
fi
