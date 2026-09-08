#compdef sys

_sys() {
  local -a subcommands=(
    'update:Update, upgrade, and clean packages'
    'install:Install a package'
    'uninstall:Remove a package'
    'deps:Check and install dependencies'
    'ps:List and manage processes'
    'self-update:Update system-cli via git pull'
    'help:Show help'
  )

  _arguments '1: :->cmd' '*:: :->args'

  case $state in
    cmd)
      _describe 'command' subcommands
      ;;
    args)
      case $words[1] in
        ps)
          _values 'subcommand' 'kill[Kill a process by PID]' '--port[Filter by port]' 'help[Show help]'
          ;;
        install|uninstall)
          _files
          ;;
      esac
      ;;
  esac
}

_sys "$@"
