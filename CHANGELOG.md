# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-07

### Added
- Initial public release of `system-cli`: `sys`, `vpn`, `run`, `conn`, `cron`, `http`, `dk`, `dkc`, `stress`.
- Multi-OS support (Debian/Ubuntu, Fedora, macOS) via `lib/os.sh` package-manager detection.
- `sys --version` / `sys version` prints the current version and git commit SHA (when available).
- bats-core test suite for `lib/os.sh` and CLI option parsers.

[Unreleased]: https://github.com/ailtonloures/system-cli/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ailtonloures/system-cli/releases/tag/v0.1.0
