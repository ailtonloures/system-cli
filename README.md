<p align="center">
  <img src="assets/logo-lockup-light.svg" alt="system-cli logo" width="160">
</p>

# system-cli

A collection of shell utilities for everyday system administration on **Debian/Ubuntu, Fedora, and macOS**.

## Tools

| Command | Description |
|---------|-------------|
| `sys`   | Package management wrapper (update, install, uninstall) — auto-detects apt/dnf/brew |
| `vpn`   | WireGuard VPN manager (connect, disconnect, switch) |
| `run`   | Script runner with interactive picker |
| `conn`  | SSH connection manager (connect, add, remove, keygen) |
| `cron`  | Cron job manager (add, remove, update, list) |
| `http`  | HTTP client with curl (requests, clients, saved requests) |

## Supported operating systems

| OS | Package manager | Notes |
|----|------------------|-------|
| Debian / Ubuntu | `apt` | Original target platform |
| Fedora / RHEL-family | `dnf` | `sudo dnf install make` if `make` isn't already present |
| macOS | `brew` ([Homebrew](https://brew.sh)) | Requires Xcode Command Line Tools (`xcode-select --install`); package commands run without `sudo` |

`sys` detects your OS/package manager automatically at runtime — no configuration needed.

## Requirements

- Bash 4+ (macOS ships Bash 3.2 by default — see the [macOS section](#macos-notes) below)
- A supported package manager: `apt`, `dnf`, or `brew`
- `wg-quick` / WireGuard (for `vpn`)
- `ssh` / OpenSSH (for `conn`) — preinstalled on macOS and most distros; `sys deps` installs it otherwise

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
```

Local package file installation is OS-specific: a `.deb` only works on Debian/Ubuntu, `.rpm` only on Fedora, and `.pkg` only on macOS. Attempting to install the wrong format for your OS produces a clear error.

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
conn remove hermes       # remove a connection
conn list                # list all configured connections
conn keygen deploy       # generate an SSH key pair (interactive type selection)
```

### cron

```bash
cron add backup '0 2 * * *' '/home/user/scripts/backup.sh'  # add with inline args
cron add cleanup                                              # add interactively
cron list                                                     # list all managed cron jobs
cron update backup                                            # update schedule or command
cron remove backup                                            # remove a cron job
```

> On macOS, remember to grant Full Disk Access to your terminal app — see [macOS notes](#macos-notes).

### http

```bash
http get https://api.example.com/users           # simple GET request
http post https://api.example.com/users \
  -d '{"name":"John"}'                            # POST with JSON body
http get /users -c myapi                          # use a named client
http client add myapi                             # add a client (interactive)
http client list                                  # list all clients
http save list-users get /users -c myapi          # save a request
http run list-users                               # replay a saved request
http history                                      # show recent requests
```

## License

MIT
