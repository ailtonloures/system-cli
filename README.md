# system-cli

A collection of shell utilities for everyday Linux system administration.

## Tools

| Command | Description |
|---------|-------------|
| `sys`   | Package management wrapper (update, install, uninstall) |
| `vpn`   | WireGuard VPN manager (connect, disconnect, switch) |
| `run`   | Script runner with interactive picker |
| `conn`  | SSH connection manager (connect, add, remove, keygen) |
| `cron`  | Cron job manager (add, remove, update, list) |

## Requirements

- Bash 4+
- `apt` package manager (Debian/Ubuntu)
- `wg-quick` / WireGuard (for `vpn`)
- `ssh` / OpenSSH (for `conn`)

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

```bash
sys update              # update, upgrade, and clean packages
sys install curl        # install an apt package
sys install ./app.deb   # install a .deb file
sys uninstall firefox   # remove a package
```

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
conn add hermes         # add a new connection (interactive)
conn remove hermes      # remove a connection
conn list               # list all configured connections
conn keygen deploy      # generate an SSH key pair (interactive type selection)
```

### cron

```bash
cron add backup '0 2 * * *' '/home/user/scripts/backup.sh'  # add with inline args
cron add cleanup                                              # add interactively
cron list                                                     # list all managed cron jobs
cron update backup                                            # update schedule or command
cron remove backup                                            # remove a cron job
```

## License

MIT
