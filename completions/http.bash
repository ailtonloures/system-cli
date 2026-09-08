_http_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    http)
      COMPREPLY=($(compgen -W "get post put delete client save run saves unsave history help --version" -- "$cur"))
      ;;
    client)
      COMPREPLY=($(compgen -W "add remove list show" -- "$cur"))
      ;;
    -c)
      local clients
      clients=$(ls ~/.config/http/clients/*.conf 2>/dev/null | xargs -I{} basename {} .conf)
      COMPREPLY=($(compgen -W "$clients" -- "$cur"))
      ;;
    run|unsave)
      local saves
      saves=$(ls ~/.config/http/saves/*.conf 2>/dev/null | xargs -I{} basename {} .conf)
      COMPREPLY=($(compgen -W "$saves" -- "$cur"))
      ;;
  esac
}
complete -F _http_completions http
