#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/ui.sh"
  source "${BATS_TEST_DIRNAME}/../lib/os.sh"
}

@test "detect_os returns a known value" {
  run detect_os
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ ^(debian|fedora|macos|unknown)$ ]]
}

@test "detect_pkg_manager returns a known value" {
  run detect_pkg_manager
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ ^(apt|dnf|brew|unknown)$ ]]
}

@test "pkg_map_name maps curl correctly" {
  local os
  os="$(detect_os)"
  run pkg_map_name curl
  [[ "$status" -eq 0 ]]
  [[ -n "$output" ]]
}

@test "pkg_map_name maps ssh-client" {
  run pkg_map_name ssh-client
  [[ "$status" -eq 0 ]]
}

@test "require_bash succeeds on bash 4+" {
  run require_bash 4
  [[ "$status" -eq 0 ]]
}
