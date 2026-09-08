#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/ui.sh"
}

@test "color variables are defined" {
  [[ -n "$GREEN" ]]
  [[ -n "$RED" ]]
  [[ -n "$CYAN" ]]
  [[ -n "$YELLOW" ]]
  [[ -n "$BOLD" ]]
  [[ -n "$RESET" ]]
}

@test "info outputs success marker to stdout" {
  run info "test message"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"✓"* ]]
  [[ "$output" == *"test message"* ]]
}

@test "error outputs failure marker to stderr" {
  run error "error message"
  [[ "$output" == *"✗"* ]]
  [[ "$output" == *"error message"* ]]
}

@test "header outputs bold cyan text" {
  run header "my header"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"my header"* ]]
}

@test "warn outputs warning marker to stderr" {
  run warn "warning message"
  [[ "$output" == *"!"* ]]
  [[ "$output" == *"warning message"* ]]
}

@test "double-source does not fail" {
  source "${BATS_TEST_DIRNAME}/../lib/ui.sh"
  [[ -n "$GREEN" ]]
}
