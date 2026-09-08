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
