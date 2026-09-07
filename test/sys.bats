# test/sys.bats — tests for bin/sys argument parsing (sys_ps dispatch).

setup() {
  ROOT_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  # No-op log helpers required before lib/os.sh is sourced by bin/sys.
  info()   { :; }
  error()  { :; }
  header() { :; }
  # shellcheck source=../bin/sys
  source "${ROOT_DIR}/bin/sys"

  # Stub out the real implementations so we only assert on how sys_ps
  # dispatches/parses its arguments, not on live process/port state.
  sys_ps_list() { echo "list:filter=${1:-<empty>}:port=${2:-<empty>}"; }
  sys_ps_kill() { echo "kill:pid=${1:-<empty>}"; }
}

@test "sys_ps: no args lists with no filters" {
  run sys_ps
  [ "$status" -eq 0 ]
  [ "$output" = "list:filter=<empty>:port=<empty>" ]
}

@test "sys_ps: name filter is forwarded to sys_ps_list" {
  run sys_ps nginx
  [ "$output" = "list:filter=nginx:port=<empty>" ]
}

@test "sys_ps: --port <port> is forwarded to sys_ps_list" {
  run sys_ps --port 3000
  [ "$output" = "list:filter=<empty>:port=3000" ]
}

@test "sys_ps: --port without a value exits non-zero" {
  run sys_ps --port
  [ "$status" -ne 0 ]
}

@test "sys_ps: kill <pid> dispatches to sys_ps_kill" {
  run sys_ps kill 1234
  [ "$output" = "kill:pid=1234" ]
}

@test "sys_ps: help prints usage and does not dispatch" {
  run sys_ps help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: sys ps"* ]]
}
