#!/usr/bin/env bash
# lib/os.sh — OS / package-manager detection middleware for system-cli.
#
# Source this from a bin/ script after its color/log helpers (info/error/header)
# are already defined, e.g.:
#
#   _src="${BASH_SOURCE[0]}"
#   while [[ -h "$_src" ]]; do
#     _dir="$(cd -P "$(dirname "$_src")" && pwd)"
#     _src="$(readlink "$_src")"
#     [[ "$_src" != /* ]] && _src="$_dir/$_src"
#   done
#   readonly SCRIPT_DIR="$(cd -P "$(dirname "$_src")" && pwd)"
#   source "${SCRIPT_DIR}/../lib/os.sh"
#
# Supported operating systems: Debian/Ubuntu (apt), Fedora/RHEL-family (dnf),
# macOS (brew).

# --- Detection ---------------------------------------------------------------

# detect_os: prints one of debian|fedora|macos|unknown
detect_os() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macos"
    return
  fi

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
      ubuntu|debian|linuxmint|pop) echo "debian"; return ;;
      fedora|rhel|centos|rocky|almalinux) echo "fedora"; return ;;
    esac
    case "${ID_LIKE:-}" in
      *debian*)          echo "debian"; return ;;
      *fedora*|*rhel*)   echo "fedora"; return ;;
    esac
  fi

  echo "unknown"
}

# detect_pkg_manager: prints one of apt|dnf|brew|unknown
detect_pkg_manager() {
  case "$(detect_os)" in
    debian) echo "apt" ;;
    fedora) echo "dnf" ;;
    macos)  echo "brew" ;;
    *)      echo "unknown" ;;
  esac
}

# pkg_manager_or_die: resolves the package manager or exits with a clear error.
pkg_manager_or_die() {
  local pm
  pm="$(detect_pkg_manager)"

  if [[ "$pm" == "unknown" ]]; then
    error "Unsupported operating system. system-cli supports Debian/Ubuntu, Fedora, and macOS."
    exit 1
  fi

  if ! command -v "$pm" &>/dev/null; then
    error "Package manager '$pm' not found on this system."
    if [[ "$pm" == "brew" ]]; then
      error "Install Homebrew first: https://brew.sh"
    fi
    exit 1
  fi

  echo "$pm"
}

# pkg_needs_sudo: exit status 0 (true) unless on brew.
pkg_needs_sudo() {
  [[ "$(detect_pkg_manager)" != "brew" ]]
}

_run_pkg() {
  if pkg_needs_sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

# require_bash <min-major-version>: exits with a helpful message if the
# running Bash is older than required. macOS ships Bash 3.2 by default.
require_bash() {
  local min="${1:-4}"
  if (( BASH_VERSINFO[0] < min )); then
    error "This command requires Bash ${min}+ (found ${BASH_VERSION})."
    if [[ "$(detect_os)" == "macos" ]]; then
      error "macOS ships an old Bash (3.2) for licensing reasons. Install a modern one:"
      error "  brew install bash"
      error "Then make sure Homebrew's bin directory comes before /bin in your PATH"
      error "(e.g. add 'export PATH=\"/opt/homebrew/bin:\$PATH\"' to your shell profile)."
    fi
    exit 1
  fi
}

# --- Logical package name -> real package name per OS ------------------------
# Usage: pkg_map_name <logical-name>
# Logical names: ssh-client, cron-daemon, wireguard, curl
# Returns an empty string when the tool ships with the OS and needs no package.
pkg_map_name() {
  local logical="$1"
  local os
  os="$(detect_os)"

  case "$logical" in
    ssh-client)
      case "$os" in
        debian) echo "openssh-client" ;;
        fedora) echo "openssh-clients" ;;
        macos)  echo "" ;;
      esac
      ;;
    cron-daemon)
      case "$os" in
        debian) echo "cron" ;;
        fedora) echo "cronie" ;;
        macos)  echo "" ;;
      esac
      ;;
    wireguard)
      case "$os" in
        debian) echo "wireguard-tools" ;;
        fedora) echo "wireguard-tools" ;;
        macos)  echo "wireguard-tools" ;;
      esac
      ;;
    lazydocker)
      case "$os" in
        debian) echo "lazydocker" ;;
        fedora) echo "lazydocker" ;;
        macos)  echo "lazydocker" ;;
      esac
      ;;
    curl)
      echo "curl"
      ;;
    *)
      echo "$logical"
      ;;
  esac
}

# --- Generic package operations ----------------------------------------------

pkg_update() {
  local pm
  pm="$(pkg_manager_or_die)"

  case "$pm" in
    apt)
      _run_pkg apt update
      _run_pkg apt upgrade -y
      _run_pkg apt autoremove -y
      ;;
    dnf)
      _run_pkg dnf upgrade --refresh -y
      _run_pkg dnf autoremove -y
      ;;
    brew)
      brew update
      brew upgrade
      brew cleanup
      ;;
  esac
}

# pkg_install <target>
# target may be a repository package name, or a local package file
# (.deb on Debian/Ubuntu, .rpm on Fedora, .pkg on macOS).
pkg_install() {
  local target="$1"
  local pm
  pm="$(pkg_manager_or_die)"

  case "$target" in
    *.deb)
      if [[ "$pm" != "apt" ]]; then
        error ".deb packages are only supported on Debian/Ubuntu (detected: ${pm})."
        exit 1
      fi
      [[ -f "$target" ]] || { error "File not found: $target"; exit 1; }
      _run_pkg dpkg -i "$target"
      _run_pkg apt -f install -y
      _run_pkg apt autoremove -y
      ;;
    *.rpm)
      if [[ "$pm" != "dnf" ]]; then
        error ".rpm packages are only supported on Fedora/RHEL-family (detected: ${pm})."
        exit 1
      fi
      [[ -f "$target" ]] || { error "File not found: $target"; exit 1; }
      _run_pkg dnf install -y "$target"
      ;;
    *.pkg)
      if [[ "$pm" != "brew" ]]; then
        error ".pkg installers are only supported on macOS (detected: ${pm})."
        exit 1
      fi
      [[ -f "$target" ]] || { error "File not found: $target"; exit 1; }
      sudo installer -pkg "$target" -target /
      ;;
    *)
      case "$pm" in
        apt)  _run_pkg apt install -y "$target" ;;
        dnf)  _run_pkg dnf install -y "$target" ;;
        brew) brew install "$target" ;;
      esac
      ;;
  esac
}

# Pinned wrk release (tag + the commit it must resolve to).
WRK_REF="4.2.0"
WRK_COMMIT="a211dd5a7050b1f9e8a9870b95513060e72ac4a0"

# _sha256 <file>: prints the SHA-256 hex digest of a file.
_sha256() {
  if command -v sha256sum &>/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# install_lazydocker: installs lazydocker from Homebrew (macOS) or GitHub
# Releases binary (Linux) into ~/.local/bin. The tarball is verified against
# the release's checksums.txt before extraction.
install_lazydocker() {
  local os
  os="$(detect_os)"

  if [[ "$os" == "macos" ]]; then
    brew install lazydocker
    return
  fi

  if ! command -v curl &>/dev/null; then
    error "curl is required to install lazydocker. Run: sys deps"
    exit 1
  fi

  local arch
  case "$(uname -m)" in
    x86_64)       arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)            error "Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac

  local headers
  if ! headers="$(curl -fsSI https://github.com/jesseduffield/lazydocker/releases/latest)"; then
    error "Could not query the latest lazydocker release (HTTP request failed)."
    exit 1
  fi
  local latest_url
  latest_url="$(printf '%s\n' "$headers" | grep -i '^location:' | tr -d '\r' | awk '{print $2}')"
  local version="${latest_url##*/}"

  if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Version check failed: unexpected lazydocker version '${version}' (expected vX.Y.Z)."
    exit 1
  fi

  local tarball="lazydocker_${version#v}_Linux_${arch}.tar.gz"
  local base_url="https://github.com/jesseduffield/lazydocker/releases/download/${version}"

  # Single EXIT trap (path expanded now, since tmp_dir is local); the previous
  # trap is restored only after the directory has been removed.
  local tmp_dir prev_trap
  tmp_dir="$(mktemp -d)"
  prev_trap="$(trap -p EXIT)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_dir}'" EXIT

  header "Downloading lazydocker ${version} for Linux ${arch}..."
  if ! curl -fsSL "${base_url}/${tarball}" -o "${tmp_dir}/${tarball}"; then
    error "Download failed: ${base_url}/${tarball}"
    exit 1
  fi
  if ! curl -fsSL "${base_url}/checksums.txt" -o "${tmp_dir}/checksums.txt"; then
    error "Download failed: ${base_url}/checksums.txt"
    exit 1
  fi

  local expected actual
  expected="$(awk -v f="$tarball" '$2 == f || $2 == "*" f {print $1; exit}' "${tmp_dir}/checksums.txt")"
  if [[ -z "$expected" ]]; then
    error "Checksum verification failed: ${tarball} not listed in checksums.txt."
    exit 1
  fi
  actual="$(_sha256 "${tmp_dir}/${tarball}")"
  if [[ "$actual" != "$expected" ]]; then
    error "Checksum verification failed for ${tarball} (expected ${expected}, got ${actual})."
    exit 1
  fi

  tar -xzf "${tmp_dir}/${tarball}" -C "$tmp_dir" lazydocker

  mkdir -p "${HOME}/.local/bin"
  mv "${tmp_dir}/lazydocker" "${HOME}/.local/bin/lazydocker"
  chmod +x "${HOME}/.local/bin/lazydocker"

  info "lazydocker ${version} installed to ~/.local/bin/lazydocker"

  rm -rf "$tmp_dir"
  eval "${prev_trap:-trap - EXIT}"
}

install_wrk() {
  local os
  os="$(detect_os)"

  if [[ "$os" == "macos" ]]; then
    brew install wrk
    return
  fi

  local -a missing=()
  command -v git &>/dev/null || missing+=(git)
  command -v make &>/dev/null || missing+=(make)
  command -v gcc &>/dev/null || missing+=(gcc)

  case "$os" in
    debian) dpkg -s libssl-dev &>/dev/null 2>&1 || missing+=(libssl-dev) ;;
    fedora) rpm -q openssl-devel &>/dev/null 2>&1 || missing+=(openssl-devel) ;;
    *)      error "Unsupported OS for wrk installation."; exit 1 ;;
  esac

  if [[ ${#missing[@]} -gt 0 ]]; then
    header "Installing build dependencies: ${missing[*]}"
    for dep in "${missing[@]}"; do
      pkg_install "$dep"
    done
  fi

  local tmp_dir prev_trap
  tmp_dir="$(mktemp -d)"
  prev_trap="$(trap -p EXIT)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_dir}'" EXIT

  header "Building wrk ${WRK_REF} from source..."
  if ! git clone --depth 1 --branch "$WRK_REF" https://github.com/wg/wrk.git "$tmp_dir/wrk"; then
    error "Could not clone wrk at ${WRK_REF}."
    exit 1
  fi

  local head
  head="$(git -C "$tmp_dir/wrk" rev-parse HEAD)"
  if [[ "$head" != "$WRK_COMMIT" ]]; then
    error "Commit check failed: wrk ${WRK_REF} resolved to ${head}, expected ${WRK_COMMIT}."
    exit 1
  fi

  make -C "$tmp_dir/wrk" -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

  mkdir -p "${HOME}/.local/bin"
  cp "$tmp_dir/wrk/wrk" "${HOME}/.local/bin/wrk"
  chmod +x "${HOME}/.local/bin/wrk"

  info "wrk installed to ~/.local/bin/wrk"

  rm -rf "$tmp_dir"
  eval "${prev_trap:-trap - EXIT}"
}

pkg_remove() {
  local pkg="$1"
  local pm
  pm="$(pkg_manager_or_die)"

  case "$pm" in
    apt)
      _run_pkg apt remove --purge -y "$pkg"
      _run_pkg apt autoremove -y
      ;;
    dnf)
      _run_pkg dnf remove -y "$pkg"
      _run_pkg dnf autoremove -y
      ;;
    brew)
      brew uninstall "$pkg"
      brew cleanup
      ;;
  esac
}
