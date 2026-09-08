_sys_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    sys)
      COMPREPLY=($(compgen -W "update install uninstall deps ps self-update help --version" -- "$cur"))
      ;;
    ps)
      COMPREPLY=($(compgen -W "kill --port help" -- "$cur"))
      ;;
    install|uninstall)
      COMPREPLY=($(compgen -f -- "$cur"))
      ;;
  esac
}
complete -F _sys_completions sys
