gh() {
  GH_TOKEN="$(op read "op://Private/GitHub/token")" command gh "$@"
}
