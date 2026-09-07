# test/http.bats — tests for bin/http option parsing.

setup() {
  ROOT_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  # Sourcing bin/http must not execute main(); the script guards on
  # BASH_SOURCE == $0, which holds true when sourced from bats.
  # shellcheck source=../bin/http
  source "${ROOT_DIR}/bin/http"
}

@test "http_parse_opts: no options leaves defaults empty" {
  http_parse_opts
  [ "$_opt_client" = "" ]
  [ "$_opt_verbose" -eq 0 ]
  [ "$_opt_data" = "" ]
  [ "${#_opt_headers[@]}" -eq 0 ]
}

@test "http_parse_opts: -c sets client" {
  http_parse_opts -c myapi
  [ "$_opt_client" = "myapi" ]
}

@test "http_parse_opts: -H is repeatable and preserves order" {
  http_parse_opts -H "X-One: 1" -H "X-Two: 2"
  [ "${#_opt_headers[@]}" -eq 2 ]
  [ "${_opt_headers[0]}" = "X-One: 1" ]
  [ "${_opt_headers[1]}" = "X-Two: 2" ]
}

@test "http_parse_opts: -d sets data" {
  http_parse_opts -d '{"a":1}'
  [ "$_opt_data" = '{"a":1}' ]
}

@test "http_parse_opts: -v sets verbose flag without consuming an arg" {
  http_parse_opts -v -c myapi
  [ "$_opt_verbose" -eq 1 ]
  [ "$_opt_client" = "myapi" ]
}

@test "http_parse_opts: combination of all options" {
  http_parse_opts -c myapi -H "Accept: json" -d 'body' -v
  [ "$_opt_client" = "myapi" ]
  [ "${_opt_headers[0]}" = "Accept: json" ]
  [ "$_opt_data" = "body" ]
  [ "$_opt_verbose" -eq 1 ]
}

@test "http_parse_opts: unknown option exits non-zero" {
  run http_parse_opts --bogus
  [ "$status" -ne 0 ]
}

@test "to_lower: lowercases mixed case string" {
  run to_lower "MixedCASE"
  [ "$output" = "mixedcase" ]
}

@test "to_upper: uppercases mixed case string" {
  run to_upper "MixedCASE"
  [ "$output" = "MIXEDCASE" ]
}
