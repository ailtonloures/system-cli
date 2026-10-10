#!/usr/bin/env bats

@test "conn help shows usage" {
  run bash "${BATS_TEST_DIRNAME}/../bin/conn" help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage: conn"* ]]
}

@test "conn --help shows usage" {
  run bash "${BATS_TEST_DIRNAME}/../bin/conn" --help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage: conn"* ]]
}

@test "conn add rejects invalid alias" {
  run bash "${BATS_TEST_DIRNAME}/../bin/conn" add "../evil"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid alias"* ]]
}

@test "conn add rejects alias with spaces" {
  run bash "${BATS_TEST_DIRNAME}/../bin/conn" add "my server"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid alias"* ]]
}

@test "conn add requires alias" {
  run bash "${BATS_TEST_DIRNAME}/../bin/conn" add
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Missing alias"* ]]
}

# --- hardening (spec 003) ---
# Pre-fix: `conn -oProxyCommand=x` was passed to `ssh` unguarded (it only
# stopped when no matching Host existed); a config with `Host -oProxyCommand=x`
# made ssh parse the alias as an option. Now rejected before any ssh call.

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME/.ssh" "${BATS_TEST_TMPDIR}/bin"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "ssh-stub $*" >> "$HOME/ssh.calls"' \
    > "${BATS_TEST_TMPDIR}/bin/ssh"
  chmod +x "${BATS_TEST_TMPDIR}/bin/ssh"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  CONN="${BATS_TEST_DIRNAME}/../bin/conn"
}

_seed_config() {
  printf '\nHost aXb\n  HostName x.example\n  User u\n  Port 22\n' > "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
}

@test "conn rejects option-like alias and never calls ssh" {
  printf '\nHost -oProxyCommand=x\n  HostName h\n' > "$HOME/.ssh/config"
  run bash "$CONN" -oProxyCommand=x
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid alias"* ]]
  [[ ! -e "$HOME/ssh.calls" ]]
}

@test "conn edit/remove reject option-like alias" {
  run bash "$CONN" edit -oProxyCommand=x
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid alias"* ]]
  run bash "$CONN" remove -oProxyCommand=x
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid alias"* ]]
}

@test "conn connect uses ssh -- with the alias" {
  _seed_config
  run bash "$CONN" aXb
  [[ "$status" -eq 0 ]]
  [[ "$(cat "$HOME/ssh.calls")" == "ssh-stub -- aXb" ]]
}

@test "conn: a.b does not match host aXb" {
  _seed_config
  run bash "$CONN" a.b
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"not found"* ]]
  [[ ! -e "$HOME/ssh.calls" ]]
}

@test "conn add rejects hostname with space; config unchanged" {
  _seed_config
  before="$(cat "$HOME/.ssh/config")"
  run bash "$CONN" add newhost <<< $'evil.com ProxyCommand id\nbob\n'
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid hostname"* ]]
  [[ "$(cat "$HOME/.ssh/config")" == "$before" ]]
}

@test "conn add rejects control chars in user" {
  _seed_config
  before="$(cat "$HOME/.ssh/config")"
  run bash "$CONN" add newhost <<< $'host.example\nbob\r\n'
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid user"* ]]
  [[ "$(cat "$HOME/.ssh/config")" == "$before" ]]
}

@test "conn add rejects spaces in identity file and proxy jump" {
  _seed_config
  run bash "$CONN" add newhost <<< $'h.example\nbob\n22\n/a b/key\n\n'
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid identity file"* ]]
  run bash "$CONN" add newhost <<< $'h.example\nbob\n22\n\njump host\n'
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid proxy jump"* ]]
  ! grep -q newhost "$HOME/.ssh/config"
}

@test "conn add writes valid host atomically with mode 600, proxy comma allowed" {
  _seed_config
  run bash "$CONN" add newhost <<< $'h.example\nbob\n2222\n~/.ssh/k\njump1,jump2\n'
  [[ "$status" -eq 0 ]]
  grep -q '^Host newhost$' "$HOME/.ssh/config"
  grep -q '  ProxyJump jump1,jump2' "$HOME/.ssh/config"
  grep -q '^Host aXb$' "$HOME/.ssh/config"
  [[ "$(stat -c %a "$HOME/.ssh/config")" == "600" ]]
  [[ -z "$(ls "$HOME/.ssh" | grep -v '^config$')" ]]
}

@test "conn add: duplicate alias with dot is literal" {
  _seed_config
  run bash "$CONN" add a.b <<< $'h.example\nbob\n22\n\n\n'
  [[ "$status" -eq 0 ]]
  grep -q '^Host a.b$' "$HOME/.ssh/config"
}

@test "conn remove drops only the exact host" {
  _seed_config
  run bash "$CONN" add a.b <<< $'h.example\nbob\n22\n\n\n'
  run bash "$CONN" remove a.b <<< 'y'
  [[ "$status" -eq 0 ]]
  ! grep -q '^Host a.b$' "$HOME/.ssh/config"
  grep -q '^Host aXb$' "$HOME/.ssh/config"
}

@test "conn: interrupted add leaves config intact and no temp file" {
  _seed_config
  before="$(cat "$HOME/.ssh/config")"
  # mv stub: the temp file already exists here; signal the script, then fail
  printf '%s\n' '#!/usr/bin/env bash' 'kill -TERM "$PPID"' 'sleep 1' 'exit 1' \
    > "${BATS_TEST_TMPDIR}/bin/mv"
  chmod +x "${BATS_TEST_TMPDIR}/bin/mv"
  run bash "$CONN" add newhost <<< $'h.example\nbob\n22\n\n\n'
  [[ "$status" -ne 0 ]]
  [[ "$(cat "$HOME/.ssh/config")" == "$before" ]]
  [[ -z "$(ls "$HOME/.ssh" | grep -v '^config$')" ]]
}
