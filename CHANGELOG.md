# Changelog

## 0.1.0

- Security: harden file permissions for http client configs and history
- Security: input validation for http client names and conn aliases
- Security: warn when running without root privileges in sys ps
- Quality: extract shared lib/ui.sh library
- Quality: add shellcheck CI and bats smoke tests
- Quality: fix fragile curl_args substitution in http
- Quality: add --version flag and versioning
