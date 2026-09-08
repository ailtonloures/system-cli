_cron_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    cron)
      COMPREPLY=($(compgen -W "add remove update list help --version" -- "$cur"))
      ;;
    remove|update)
      local jobs
      jobs=$(crontab -l 2>/dev/null | grep '^# cron:' | sed 's/^# cron://')
      COMPREPLY=($(compgen -W "$jobs" -- "$cur"))
      ;;
  esac
}
complete -F _cron_completions cron
