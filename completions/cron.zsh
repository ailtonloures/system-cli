#compdef cron

_cron() {
  local -a subcommands=(
    'add:Add a new cron job'
    'remove:Remove a cron job'
    'update:Update an existing cron job'
    'list:List all managed cron jobs'
    'help:Show help'
  )

  _arguments '1: :->cmd' '*:: :->args'

  case $state in
    cmd)
      _describe 'command' subcommands
      ;;
    args)
      case $words[1] in
        remove|update)
          local -a jobs
          jobs=(${(f)"$(crontab -l 2>/dev/null | grep '^# cron:' | sed 's/^# cron://')"})
          _describe 'cron job' jobs
          ;;
      esac
      ;;
  esac
}

_cron "$@"
