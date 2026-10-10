#!/usr/bin/env bats

@test "http help shows usage" {
  run bash "${BATS_TEST_DIRNAME}/../bin/http" help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage: http"* ]]
}

@test "http --help shows usage" {
  run bash "${BATS_TEST_DIRNAME}/../bin/http" --help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage: http"* ]]
}

@test "http with no args shows help" {
  run bash "${BATS_TEST_DIRNAME}/../bin/http"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage: http"* ]]
}

@test "http unknown command fails" {
  run bash "${BATS_TEST_DIRNAME}/../bin/http" foobar
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Unknown command"* ]]
}

@test "http client add rejects path traversal name" {
  run bash "${BATS_TEST_DIRNAME}/../bin/http" client add "../evil"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid"* ]]
}

# --- secret handling ---

_http_setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME" "${BATS_TEST_TMPDIR}/stubs"
  cat > "${BATS_TEST_TMPDIR}/stubs/curl" <<'STUB'
#!/usr/bin/env bash
for a in "$@"; do
  if [[ "$a" == "-v" ]]; then
    echo "> GET /users HTTP/1.1" >&2
    for b in "$@"; do
      [[ "$b" == Authorization:* ]] && echo "> $b" >&2
    done
  fi
done
printf 'ok\n200'
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/curl"
  export PATH="${BATS_TEST_TMPDIR}/stubs:${PATH}"
  mkdir -p "$HOME/.config/http/clients"
  printf 'base_url=https://api.example.com\nauth_token=Bearer sup3rs3cr3ttoken1234\n' \
    > "$HOME/.config/http/clients/myapi.conf"
}

@test "http client show masks token by default" {
  _http_setup
  run bash "${BATS_TEST_DIRNAME}/../bin/http" client show myapi
  [[ "$status" -eq 0 ]]
  [[ "$output" != *"sup3rs3cr3ttoken1234"* ]]
  [[ "$output" == *"1234"* ]]
}

@test "http client show --reveal prints full token" {
  _http_setup
  run bash "${BATS_TEST_DIRNAME}/../bin/http" client show myapi --reveal
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Bearer sup3rs3cr3ttoken1234"* ]]
}

@test "http -v does not print the Authorization token" {
  _http_setup
  run bash "${BATS_TEST_DIRNAME}/../bin/http" get /users -c myapi -v
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Authorization:"* ]]
  [[ "$output" != *"sup3rs3cr3ttoken1234"* ]]
}

@test "http history drops query string and fragment" {
  _http_setup
  run bash "${BATS_TEST_DIRNAME}/../bin/http" get "https://api.example.com/x?token=abc123#frag"
  [[ "$status" -eq 0 ]]
  run cat "$HOME/.config/http/history.log"
  [[ "$output" == *"https://api.example.com/x|"* ]]
  [[ "$output" != *"abc123"* ]]
  [[ "$output" != *"frag"* ]]
}

@test "http history sanitizes pipes and newlines in URL" {
  _http_setup
  run bash "${BATS_TEST_DIRNAME}/../bin/http" get $'https://a.example.com/p|x\nforged|GET|http://evil|200'
  [[ "$status" -eq 0 ]]
  [[ "$(wc -l < "$HOME/.config/http/history.log")" -eq 1 ]]
  [[ "$(awk -F'|' '{print NF}' "$HOME/.config/http/history.log")" -eq 4 ]]
}

@test "http preserves 700/600 permissions" {
  _http_setup
  run bash "${BATS_TEST_DIRNAME}/../bin/http" get https://api.example.com/x
  [[ "$(stat -c %a "$HOME/.config/http" 2>/dev/null || stat -f %Lp "$HOME/.config/http")" == "700" ]]
  [[ "$(stat -c %a "$HOME/.config/http/history.log" 2>/dev/null || stat -f %Lp "$HOME/.config/http/history.log")" == "600" ]]
}
