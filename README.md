# system-cli

A collection of shell utilities for everyday Linux system administration.

## Tools

| Command | Description |
|---------|-------------|
| `sys`   | Package management wrapper (update, install, uninstall) |
| `vpn`   | WireGuard VPN manager (connect, disconnect, switch) |
| `run`   | Script runner with interactive picker |

## Requirements

- Bash 4+
- `apt` package manager (Debian/Ubuntu)
- `wg-quick` / WireGuard (for `vpn`)

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

## License

MIT
