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
#
# Testing: detect_os() reads the os-release file from $OS_RELEASE_FILE when
# set, defaulting to /etc/os-release. Tests can point this at a fixture file
# instead of mocking the real filesystem.

# --- Detection ---------------------------------------------------------------

# detect_os: prints one of debian|fedora|macos|unknown
detect_os() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macos"
    return
  fi

  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  if [[ -f "$os_release_file" ]]; then
    # shellcheck disable=SC1090
    source "$os_release_file"
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

# install_lazydocker: installs lazydocker from Homebrew (macOS) or GitHub
# Releases binary (Linux) into ~/.local/bin.
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

  local latest_url
  latest_url="$(curl -sI https://github.com/jesseduffield/lazydocker/releases/latest \
    | grep -i '^location:' | tr -d '\r' | awk '{print $2}')"
  local version="${latest_url##*/}"

  local tarball="lazydocker_${version#v}_Linux_${arch}.tar.gz"
  local download_url="https://github.com/jesseduffield/lazydocker/releases/download/${version}/${tarball}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  header "Downloading lazydocker ${version} for Linux ${arch}..."
  curl -sL "$download_url" -o "${tmp_dir}/${tarball}"
  tar -xzf "${tmp_dir}/${tarball}" -C "$tmp_dir"

  mkdir -p "${HOME}/.local/bin"
  mv "${tmp_dir}/lazydocker" "${HOME}/.local/bin/lazydocker"
  chmod +x "${HOME}/.local/bin/lazydocker"

  info "lazydocker ${version} installed to ~/.local/bin/lazydocker"

  trap - EXIT
  rm -rf "$tmp_dir"
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

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  header "Building wrk from source..."
  git clone --depth 1 https://github.com/wg/wrk.git "$tmp_dir/wrk"
  make -C "$tmp_dir/wrk" -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

  mkdir -p "${HOME}/.local/bin"
  cp "$tmp_dir/wrk/wrk" "${HOME}/.local/bin/wrk"
  chmod +x "${HOME}/.local/bin/wrk"

  info "wrk installed to ~/.local/bin/wrk"

  trap - EXIT
  rm -rf "$tmp_dir"
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
