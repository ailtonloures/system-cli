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
