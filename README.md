<p align="center">
  <img src="assets/logo-lockup-light.svg" alt="system-cli logo" width="160">
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/tag/ailtonloures/system-cli?label=version&sort=semver" alt="Version">
  <img src="https://img.shields.io/github/license/ailtonloures/system-cli" alt="License">
  <img src="https://img.shields.io/github/actions/workflow/status/ailtonloures/system-cli/test.yml?label=tests" alt="Tests">
  <img src="https://img.shields.io/github/actions/workflow/status/ailtonloures/system-cli/lint.yml?label=lint" alt="Lint">
  <img src="https://img.shields.io/badge/shell-bash-blue" alt="Shell">
  <img src="https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey" alt="Platform">
</p>

# system-cli

A collection of shell utilities for everyday system administration on **Debian/Ubuntu, Fedora, and macOS**.

## Why system-cli?

Every one of these tools already exists on its own — `apt`, `wg-quick`, `crontab`, `curl`, `docker compose`, `wrk`. What doesn't exist by default is **one consistent interface** across them, and one that follows you between machines.

- **One command set, any OS.** `sys` auto-detects `apt`/`dnf`/`brew` at runtime — the same muscle memory works on your Ubuntu server, your Fedora box, and your Mac, no per-OS cheat sheet.
- **Less context switching.** Stop juggling raw `wg-quick`, `crontab -e`, and ad-hoc `curl` flags. `vpn`, `cron`, and `http` wrap them with sane defaults, an interactive picker, and saved presets — the parts you'd otherwise re-Google every few months.
- **Built for the terminal-first workflow.** No GUI, no daemon, no config file to maintain beyond what each tool already needs — `dk` even drops you straight into `lazydocker`'s TUI instead of reinventing one.
- **Small and inspectable.** Pure Bash, `make install` just symlinks scripts into `~/.local/bin`. Nothing to compile, no hidden dependencies beyond the package manager you already have — read any script in under a minute.
- **Grows with real usage.** Every tool here (`sys ps` port filters, `stress` via `wrk`, `dkc` shorthand) was added because a real sysadmin/dev task needed it, not speculative feature creep.

If you're the kind of person who SSHes into three different distros a week and is tired of remembering which flavor of package manager you're on, this is for you.

## Tools

| Command | Description |
|---------|-------------|
| `sys`   | System manager — packages (update, install, uninstall) and processes (list, filter, kill) — auto-detects apt/dnf/brew |
| `vpn`   | WireGuard VPN manager (connect, disconnect, switch) |
| `run`   | Script runner with interactive picker |
| `conn`  | SSH connection manager (connect, add, remove, keygen) |
| `cron`  | Cron job manager (add, remove, update, list) |
| `http`  | HTTP client with curl (requests, clients, saved requests) |
| `dk`    | Docker manager — launches lazydocker TUI |
| `dkc`   | Docker Compose shorthand — wraps `docker compose` with convenient aliases |
| `stress`| HTTP stress testing with wrk (auto-installed) |

## Supported operating systems

| OS | Package manager | Notes |
|----|------------------|-------|
| Debian / Ubuntu | `apt` | Original target platform |
| Fedora / RHEL-family | `dnf` | `sudo dnf install make` if `make` isn't already present |
| macOS | `brew` ([Homebrew](https://brew.sh)) | Requires Xcode Command Line Tools (`xcode-select --install`); package commands run without `sudo` |

`sys` detects your OS/package manager automatically at runtime → no configuration needed.

## Requirements

- Bash 4+ (macOS ships Bash 3.2 by default → see the [macOS section](#macos-notes) below)
- A supported package manager: `apt`, `dnf`, or `brew`
- `wg-quick` / WireGuard (for `vpn`)
- `ssh` / OpenSSH (for `conn`) — preinstalled on macOS and most distros; `sys deps` installs it otherwise
- Docker (for `dk`, `dkc`) — lazydocker is installed automatically via `sys deps` or on first run of `dk`
- `wrk` (for `stress`) — installed automatically on first run

### macOS notes

- **Bash version**: macOS's built-in `/bin/bash` is version 3.2 (frozen for licensing reasons). Most `system-cli` scripts work fine on it, but for full compatibility (and to silence any future Bash 4+ syntax) install a modern Bash:
  ```bash
  brew install bash
  ```
  Then make sure Homebrew's bin directory comes before `/bin` in your `PATH` (e.g. add `export PATH="/opt/homebrew/bin:$PATH"` to your shell profile).
- **`cron`**: on modern macOS (Catalina+), `cron`/`crontab` require granting **Full Disk Access** to your terminal app in System Settings → Privacy & Security, or scheduled jobs may silently fail to run.
- **No `sudo` for package operations**: Homebrew intentionally runs as your user, not root. `sys` already accounts for this and won't prepend `sudo` on macOS.

## Installation

```bash
git clone <repo-url> ~/.local/share/system-cli
cd ~/.local/share/system-cli
make install
```

This symlinks the scripts into `~/.local/bin`. Make sure `~/.local/bin` is in your `PATH`.

To remove:

```bash
make uninstall
```

## Usage

### sys

`sys` auto-detects your OS and package manager (apt/dnf/brew), so the same commands work everywhere.

```bash
sys update              # update, upgrade, and clean packages
sys install curl        # install a repository package
sys install ./app.deb   # install a local package file (Debian/Ubuntu → .deb)
sys install ./app.rpm   # install a local package file (Fedora → .rpm)
sys install ./app.pkg   # install a local package file (macOS → .pkg)
sys uninstall firefox   # remove a package
sys deps                # check and install missing dependencies for all tools
sys self-update         # update system-cli to the latest version
```

Local package file installation is OS-specific: a `.deb` only works on Debian/Ubuntu, `.rpm` only on Fedora, and `.pkg` only on macOS. Attempting to install the wrong format for your OS produces a clear error.

#### sys ps

List and manage system processes. Shows PID, CPU%, memory%, command name, executable path, and listening port (if any).

```bash
sys ps                  # list all processes sorted by CPU usage
sys ps node             # filter processes by name
sys ps --port 3000      # filter processes by listening port
sys ps node --port 8080 # combine name and port filters
sys ps kill 1234        # kill a process by PID (with confirmation)
```

The `kill` subcommand sends `SIGTERM` first. If the process survives after 2 seconds, it offers to escalate to `SIGKILL`.

> **Note:** port detection uses `ss` (Linux) or `lsof` (macOS) and may require `sudo` for full visibility of ports owned by other users. Requires Bash 4+.

### vpn

```bash
vpn up work             # connect to a WireGuard config
vpn down work           # disconnect
vpn switch home         # disconnect all, then connect to home
vpn show                # list active VPN interfaces
```

### run

```bash
run                     # pick a script interactively from ~/Scripts
run backup              # run ~/Scripts/backup.sh directly
```

Set `SCRIPTS_DIR` to change the default scripts directory.

### conn

```bash
conn hermes             # connect to a saved SSH host
conn add hermes          # add a new connection (interactive)
conn edit hermes         # edit an existing connection
conn remove hermes       # remove a connection
conn list                # list all configured connections
conn keygen deploy       # generate an SSH key pair (interactive type selection)
```

### cron

```bash
cron add backup '0 2 * * *' '/home/user/scripts/backup.sh'  # add with inline args
cron add cleanup                                              # add interactively
cron list                                                      # list all managed cron jobs
cron update backup                                             # update schedule or command
cron remove backup                                              # remove a cron job
```

> On macOS, remember to grant Full Disk Access to your terminal app — see [macOS notes](#macos-notes).

### dk

```bash
dk              # open lazydocker
dk --help       # show help
```

Requires Docker to be running. If `lazydocker` is not installed, `dk` will install it automatically (from Homebrew on macOS, or from GitHub Releases on Linux).

### http

```bash
http get https://api.example.com/users           # simple GET request
http post https://api.example.com/users \
  -d '{"name":"John"}'                               # POST with JSON body
http get /users -c myapi                            # use a named client
http client add myapi                            # add a client (interactive)
http client show myapi                           # show client details
http client remove myapi                         # remove a client
http client list                                  # list all clients
http save list-users get /users -c myapi          # save a request
http run list-users                               # replay a saved request
http saves                                        # list saved requests
http unsave list-users                            # remove a saved request
http history                                   # show recent requests
```

### dkc

Shorthand for `docker compose`. Any unrecognized command is forwarded directly.

```bash
dkc up -d               # start services in detached mode
dkc down                # stop and remove services
dkc start               # start stopped services
dkc stop                # stop services without removing them
dkc restart             # restart services
dkc logs api            # follow logs for a service
dkc exec web bash       # exec into a running service
dkc run web bash        # run a one-off command in a service
dkc ps                  # list running services
dkc build               # build or rebuild services
dkc pull                # pull service images
dkc config              # forwarded to docker compose as-is
```

### stress

HTTP stress testing powered by [wrk](https://github.com/wg/wrk). Installs `wrk` automatically if not present.

```bash
stress quick https://api.example.com/health          # quick test (4 threads, 100 connections, 10s)
stress run https://api.example.com/users \
  -t 8 -c 200 -d 30s                                # custom threads, connections, duration
```

## License

MIT
