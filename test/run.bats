#!/usr/bin/env bats

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export SCRIPTS_DIR="$BATS_TEST_TMPDIR/scripts"
  mkdir -p "$HOME" "$SCRIPTS_DIR"
  chmod 755 "$SCRIPTS_DIR"
  printf '#!/usr/bin/env bash\necho ran-ok\n' > "$SCRIPTS_DIR/hello.sh"
  chmod 755 "$SCRIPTS_DIR/hello.sh"
  RUN="${BATS_TEST_DIRNAME}/../bin/run"
}

@test "run executes a safe script" {
  run bash "$RUN" hello
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"ran-ok"* ]]
}

@test "run executes a safe script with .sh extension" {
  run bash "$RUN" hello.sh
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"ran-ok"* ]]
}

@test "run refuses a script writable by others" {
  chmod 666 "$SCRIPTS_DIR/hello.sh"
  run bash "$RUN" hello
  [[ "$status" -ne 0 ]]
  [[ "$output" != *"ran-ok"* ]]
  [[ "$output" == *"chmod go-w"* ]]
}

@test "run refuses a script writable by group" {
  chmod 770 "$SCRIPTS_DIR/hello.sh"
  run bash "$RUN" hello
  [[ "$status" -ne 0 ]]
  [[ "$output" != *"ran-ok"* ]]
}

@test "run refuses a scripts directory writable by others" {
  chmod 777 "$SCRIPTS_DIR"
  run bash "$RUN" hello
  [[ "$status" -ne 0 ]]
  [[ "$output" != *"ran-ok"* ]]
  [[ "$output" == *"chmod go-w"* ]]
}

@test "run picker refuses a scripts directory writable by others" {
  chmod 777 "$SCRIPTS_DIR"
  run bash "$RUN" <<< "1"
  [[ "$status" -ne 0 ]]
  [[ "$output" != *"ran-ok"* ]]
}

@test "run picker refuses an unsafe script" {
  chmod 666 "$SCRIPTS_DIR/hello.sh"
  run bash "$RUN" <<< "1"
  [[ "$status" -ne 0 ]]
  [[ "$output" != *"ran-ok"* ]]
}

@test "run picker executes a safe script" {
  run bash "$RUN" <<< "1"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"ran-ok"* ]]
}

@test "run rejects path traversal in name" {
  printf '#!/usr/bin/env bash\necho evil\n' > "$BATS_TEST_TMPDIR/x.sh"
  chmod 755 "$BATS_TEST_TMPDIR/x.sh"
  run bash "$RUN" ../x
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid script name"* ]]
  [[ "$output" != *"evil"* ]]
}

@test "run rejects names containing a slash" {
  run bash "$RUN" sub/hello
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid script name"* ]]
}
