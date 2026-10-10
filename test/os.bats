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

# --- Installer integrity (lazydocker / wrk) ----------------------------------
# Stubs for curl/git/make/... are placed first on PATH; HOME and TMPDIR are
# isolated so we can assert on ~/.local/bin and on leftover temp directories.

_make_stubs() {
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  FIXTURES="${BATS_TEST_TMPDIR}/fixtures"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export TMPDIR="${BATS_TEST_TMPDIR}/tmp"
  mkdir -p "$STUBS" "$FIXTURES" "$HOME" "$TMPDIR"

  # Real tarball containing a fake lazydocker binary.
  printf '#!/bin/sh\necho lazydocker\n' > "${FIXTURES}/lazydocker"
  tar -czf "${FIXTURES}/lazydocker.tar.gz" -C "$FIXTURES" lazydocker
  if command -v sha256sum &>/dev/null; then
    GOOD_SHA="$(sha256sum "${FIXTURES}/lazydocker.tar.gz" | awk '{print $1}')"
  else
    GOOD_SHA="$(shasum -a 256 "${FIXTURES}/lazydocker.tar.gz" | awk '{print $1}')"
  fi
  export FIXTURES GOOD_SHA

  cat > "${STUBS}/uname" <<'STUB'
#!/bin/sh
case "$1" in
  -s) echo Linux ;;
  -m) echo x86_64 ;;
  *)  echo Linux ;;
esac
STUB

  cat > "${STUBS}/curl" <<'STUB'
#!/bin/bash
out=""; head=0; url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="$2"; shift ;;
    -*I*) head=1 ;;
    -*) ;;
    *) url="$1" ;;
  esac
  shift
done
if [[ "$head" -eq 1 ]]; then
  [[ "${STUB_HTTP_FAIL:-}" == "head" ]] && exit 22
  printf 'HTTP/2 302\r\nlocation: https://github.com/jesseduffield/lazydocker/releases/tag/%s\r\n' "$STUB_VERSION"
elif [[ "$url" == */checksums.txt ]]; then
  [[ "${STUB_HTTP_FAIL:-}" == "checksums" ]] && exit 22
  printf '%s  lazydocker_0.24.1_Linux_x86_64.tar.gz\n' "${STUB_SHA}" > "$out"
else
  [[ "${STUB_HTTP_FAIL:-}" == "tarball" ]] && exit 22
  cp "${FIXTURES}/lazydocker.tar.gz" "$out"
fi
STUB

  # wrk build chain: git clone creates a tree, rev-parse reports STUB_HEAD.
  cat > "${STUBS}/git" <<'STUB'
#!/bin/bash
case "$1" in
  clone) dest="${@: -1}"; mkdir -p "$dest"; printf 'all:\n\ttouch wrk\n' > "$dest/Makefile" ;;
  -C)    echo "$STUB_HEAD" ;;
esac
STUB
  printf '#!/bin/sh\nexit 0\n' > "${STUBS}/dpkg"
  cp "${STUBS}/dpkg" "${STUBS}/rpm"
  cp "${STUBS}/dpkg" "${STUBS}/gcc"
  # make stub: creates the binary without compiling
  cat > "${STUBS}/make" <<'STUB'
#!/bin/bash
dir=""; [[ "$1" == "-C" ]] && dir="$2"
printf '#!/bin/sh\n' > "$dir/wrk"
STUB
  chmod +x "${STUBS}"/*
  export PATH="${STUBS}:${PATH}"
  export STUB_VERSION="v0.24.1" STUB_SHA="$GOOD_SHA"
}

# _run_installer <function>: runs it in a fresh bash so exit does not kill bats.
_run_installer() {
  run bash -c 'source "$1/../lib/ui.sh"; source "$1/../lib/os.sh"; "$2"' _ "$BATS_TEST_DIRNAME" "$1"
}

_tmp_is_empty() {
  [[ -z "$(ls -A "$TMPDIR")" ]]
}

@test "install_lazydocker installs a verified release and cleans tmp" {
  [[ "$(uname -s)" == "Darwin" ]] && skip "Linux-only installer path"
  _make_stubs
  _run_installer install_lazydocker
  [[ "$status" -eq 0 ]]
  [[ -x "${HOME}/.local/bin/lazydocker" ]]
  _tmp_is_empty
}

@test "install_lazydocker aborts on checksum mismatch" {
  [[ "$(uname -s)" == "Darwin" ]] && skip "Linux-only installer path"
  _make_stubs
  export STUB_SHA="0000000000000000000000000000000000000000000000000000000000000000"
  _run_installer install_lazydocker
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Checksum verification failed"* ]]
  [[ ! -e "${HOME}/.local/bin/lazydocker" ]]
  _tmp_is_empty
}

@test "install_lazydocker aborts on malformed version" {
  [[ "$(uname -s)" == "Darwin" ]] && skip "Linux-only installer path"
  _make_stubs
  export STUB_VERSION="v1.2.3/../../evil"
  _run_installer install_lazydocker
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Version check failed"* ]]
  [[ ! -e "${HOME}/.local/bin/lazydocker" ]]
}

@test "install_lazydocker aborts when the version lookup returns an HTTP error" {
  [[ "$(uname -s)" == "Darwin" ]] && skip "Linux-only installer path"
  _make_stubs
  export STUB_HTTP_FAIL=head
  _run_installer install_lazydocker
  [[ "$status" -ne 0 ]]
  [[ ! -e "${HOME}/.local/bin/lazydocker" ]]
}

@test "install_lazydocker aborts when the tarball download fails and cleans tmp" {
  [[ "$(uname -s)" == "Darwin" ]] && skip "Linux-only installer path"
  _make_stubs
  export STUB_HTTP_FAIL=tarball
  _run_installer install_lazydocker
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Download failed"* ]]
  [[ ! -e "${HOME}/.local/bin/lazydocker" ]]
  _tmp_is_empty
}

@test "install_wrk installs the pinned commit and cleans tmp" {
  [[ "$(detect_os)" =~ ^(debian|fedora)$ ]] || skip "wrk build path needs Debian/Fedora"
  _make_stubs
  export STUB_HEAD
  STUB_HEAD="$(bash -c 'source "$1/../lib/os.sh"; echo "$WRK_COMMIT"' _ "$BATS_TEST_DIRNAME")"
  _run_installer install_wrk
  [[ "$status" -eq 0 ]]
  [[ -x "${HOME}/.local/bin/wrk" ]]
  _tmp_is_empty
}

@test "install_wrk aborts when the commit does not match the pin" {
  [[ "$(detect_os)" =~ ^(debian|fedora)$ ]] || skip "wrk build path needs Debian/Fedora"
  _make_stubs
  export STUB_HEAD="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
  _run_installer install_wrk
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Commit check failed"* ]]
  [[ ! -e "${HOME}/.local/bin/wrk" ]]
  _tmp_is_empty
}
