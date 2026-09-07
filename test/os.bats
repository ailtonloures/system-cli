# test/os.bats — tests for lib/os.sh detection logic.

setup() {
  ROOT_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  # Provide no-op color/log helpers required by lib/os.sh before sourcing it.
  info()   { :; }
  error()  { :; }
  header() { :; }
  # shellcheck source=../lib/os.sh
  source "${ROOT_DIR}/lib/os.sh"

  FIXTURE_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
  unset OS_RELEASE_FILE
}

write_os_release() {
  cat > "${FIXTURE_DIR}/os-release" <<EOF
$1
EOF
  OS_RELEASE_FILE="${FIXTURE_DIR}/os-release"
}

@test "detect_os: ubuntu -> debian" {
  write_os_release 'ID=ubuntu
ID_LIKE=debian'
  run detect_os
  [ "$status" -eq 0 ]
  [ "$output" = "debian" ]
}

@test "detect_os: debian -> debian" {
  write_os_release 'ID=debian'
  run detect_os
  [ "$output" = "debian" ]
}

@test "detect_os: pop os-release -> debian via ID" {
  write_os_release 'ID=pop
ID_LIKE="ubuntu debian"'
  run detect_os
  [ "$output" = "debian" ]
}

@test "detect_os: fedora -> fedora" {
  write_os_release 'ID=fedora'
  run detect_os
  [ "$output" = "fedora" ]
}

@test "detect_os: rocky -> fedora" {
  write_os_release 'ID=rocky
ID_LIKE="rhel centos fedora"'
  run detect_os
  [ "$output" = "fedora" ]
}

@test "detect_os: unknown ID falls back to ID_LIKE debian" {
  write_os_release 'ID=somedistro
ID_LIKE=debian'
  run detect_os
  [ "$output" = "debian" ]
}

@test "detect_os: completely unknown distro -> unknown" {
  write_os_release 'ID=somedistro
ID_LIKE=somethingelse'
  run detect_os
  [ "$output" = "unknown" ]
}

@test "detect_os: missing os-release file -> unknown (non-Darwin)" {
  OS_RELEASE_FILE="${FIXTURE_DIR}/does-not-exist"
  run detect_os
  [ "$output" = "unknown" ]
}

@test "detect_pkg_manager: debian -> apt" {
  write_os_release 'ID=debian'
  run detect_pkg_manager
  [ "$output" = "apt" ]
}

@test "detect_pkg_manager: fedora -> dnf" {
  write_os_release 'ID=fedora'
  run detect_pkg_manager
  [ "$output" = "dnf" ]
}

@test "detect_pkg_manager: unknown -> unknown" {
  write_os_release 'ID=somedistro
ID_LIKE=somethingelse'
  run detect_pkg_manager
  [ "$output" = "unknown" ]
}

@test "pkg_map_name: ssh-client on debian" {
  write_os_release 'ID=debian'
  run pkg_map_name ssh-client
  [ "$output" = "openssh-client" ]
}

@test "pkg_map_name: ssh-client on fedora" {
  write_os_release 'ID=fedora'
  run pkg_map_name ssh-client
  [ "$output" = "openssh-clients" ]
}

@test "pkg_map_name: cron-daemon on debian" {
  write_os_release 'ID=debian'
  run pkg_map_name cron-daemon
  [ "$output" = "cron" ]
}

@test "pkg_map_name: cron-daemon on fedora" {
  write_os_release 'ID=fedora'
  run pkg_map_name cron-daemon
  [ "$output" = "cronie" ]
}

@test "pkg_map_name: wireguard is same across distros" {
  write_os_release 'ID=debian'
  run pkg_map_name wireguard
  [ "$output" = "wireguard-tools" ]
}

@test "pkg_map_name: curl maps to curl regardless of OS" {
  write_os_release 'ID=fedora'
  run pkg_map_name curl
  [ "$output" = "curl" ]
}

@test "pkg_map_name: unknown logical name passthrough" {
  write_os_release 'ID=debian'
  run pkg_map_name some-random-tool
  [ "$output" = "some-random-tool" ]
}

@test "pkg_needs_sudo: true on debian" {
  write_os_release 'ID=debian'
  run pkg_needs_sudo
  [ "$status" -eq 0 ]
}
