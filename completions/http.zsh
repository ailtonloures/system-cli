#compdef http

_http() {
  local -a subcommands=(
    'get:Send a GET request'
    'post:Send a POST request'
    'put:Send a PUT request'
    'delete:Send a DELETE request'
    'client:Manage named clients'
    'save:Save a request for replay'
    'run:Replay a saved request'
    'saves:List saved requests'
    'unsave:Remove a saved request'
    'history:Show recent requests'
    'help:Show help'
  )

  _arguments '1: :->cmd' '*:: :->args'

  case $state in
    cmd)
      _describe 'command' subcommands
      ;;
    args)
      case $words[1] in
        client)
          _values 'subcommand' 'add[Add a named client]' 'remove[Remove a client]' 'list[List all clients]' 'show[Show client details]'
          ;;
        run|unsave)
          local -a saves
          saves=(${(f)"$(ls ~/.config/http/saves/*.conf 2>/dev/null | xargs -I{} basename {} .conf)"})
          _describe 'saved request' saves
          ;;
      esac
      ;;
  esac
}

_http "$@"
