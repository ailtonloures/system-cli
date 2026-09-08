_conn_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    conn)
      COMPREPLY=($(compgen -W "add remove edit list keygen help --version" -- "$cur"))
      ;;
    remove|edit)
      local hosts
      hosts=$(awk '/^Host / && $2 != "*" {print $2}' ~/.ssh/config 2>/dev/null)
      COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
      ;;
  esac
}
complete -F _conn_completions conn
