#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/ui.sh"
}

# --- http name validation ---

_validate_name() {
  local name="$1" label="${2:-name}"
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Invalid ${label} '${name}'. Use only letters, digits, hyphens, and underscores."
    return 1
  fi
}

@test "http: valid client names are accepted" {
  run _validate_name "my-api"
  [[ "$status" -eq 0 ]]
  run _validate_name "api_v2"
  [[ "$status" -eq 0 ]]
  run _validate_name "Test123"
  [[ "$status" -eq 0 ]]
}

@test "http: path traversal in name is rejected" {
  run _validate_name "../evil"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid"* ]]
}

@test "http: name with spaces is rejected" {
  run _validate_name "my api"
  [[ "$status" -ne 0 ]]
}

@test "http: name with slashes is rejected" {
  run _validate_name "foo/bar"
  [[ "$status" -ne 0 ]]
}

# --- conn alias validation ---

_validate_alias() {
  local alias="$1"
  if [[ ! "$alias" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    error "Invalid alias '$alias'. Use only letters, digits, dots, hyphens, and underscores."
    return 1
  fi
}

@test "conn: valid aliases are accepted" {
  run _validate_alias "my-server"
  [[ "$status" -eq 0 ]]
  run _validate_alias "prod.db"
  [[ "$status" -eq 0 ]]
  run _validate_alias "host_01"
  [[ "$status" -eq 0 ]]
}

@test "conn: regex metacharacters in alias are rejected" {
  run _validate_alias ".*"
  [[ "$status" -ne 0 ]]
}

@test "conn: alias with spaces is rejected" {
  run _validate_alias "my server"
  [[ "$status" -ne 0 ]]
}

# --- port validation ---

_validate_port() {
  local port="$1"
  if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    error "Invalid port '$port'. Must be a number between 1 and 65535."
    return 1
  fi
}

@test "conn: valid ports are accepted" {
  run _validate_port "22"
  [[ "$status" -eq 0 ]]
  run _validate_port "8080"
  [[ "$status" -eq 0 ]]
  run _validate_port "65535"
  [[ "$status" -eq 0 ]]
}

@test "conn: port 0 is rejected" {
  run _validate_port "0"
  [[ "$status" -ne 0 ]]
}

@test "conn: port above 65535 is rejected" {
  run _validate_port "70000"
  [[ "$status" -ne 0 ]]
}

@test "conn: non-numeric port is rejected" {
  run _validate_port "abc"
  [[ "$status" -ne 0 ]]
}
