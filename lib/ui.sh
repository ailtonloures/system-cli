#!/usr/bin/env bash
# lib/ui.sh — shared colors and output helpers for system-cli

[[ -n "${_SYSTEM_CLI_UI_LOADED:-}" ]] && return 0
_SYSTEM_CLI_UI_LOADED=1

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

info()   { echo -e "${GREEN}✓${RESET} $*"; }
error()  { echo -e "${RED}✗${RESET} $*" >&2; }
header() { echo -e "${BOLD}${CYAN}$*${RESET}"; }
warn()   { echo -e "${YELLOW}!${RESET} $*" >&2; }

show_version() {
  local caller="${BASH_SOURCE[1]}"
  local dir
  dir="$(cd -P "$(dirname "$caller")" && pwd)"
  local version_file="${dir}/../VERSION"
  local cmd_name
  cmd_name="$(basename "$caller")"
  if [[ -f "$version_file" ]]; then
    echo "${cmd_name} $(cat "$version_file") (system-cli)"
  else
    echo "${cmd_name} (version unknown)"
  fi
}
