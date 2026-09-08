#compdef conn

_conn() {
  local -a subcommands=(
    'add:Add a new SSH connection'
    'remove:Remove a saved connection'
    'edit:Edit an existing connection'
    'list:List all configured connections'
    'keygen:Generate an SSH key pair'
    'help:Show help'
  )

  _arguments '1: :->cmd' '*:: :->args'

  case $state in
    cmd)
      _describe 'command' subcommands
      ;;
    args)
      case $words[1] in
        remove|edit)
          local -a hosts
          hosts=(${(f)"$(awk '/^Host / && $2 != "*" {print $2}' ~/.ssh/config 2>/dev/null)"})
          _describe 'host' hosts
          ;;
      esac
      ;;
  esac
}

_conn "$@"
