#!/usr/bin/env bats

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
  export WRK_LOG="$BATS_TEST_TMPDIR/wrk.log"
  printf '#!/usr/bin/env bash\necho "$@" >> "$WRK_LOG"\necho wrk-stub\n' > "$BATS_TEST_TMPDIR/bin/wrk"
  chmod 755 "$BATS_TEST_TMPDIR/bin/wrk"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  STRESS="${BATS_TEST_DIRNAME}/../bin/stress"
}

@test "stress rejects non-numeric threads" {
  run bash "$STRESS" run http://localhost -t abc
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
}

@test "stress rejects zero connections" {
  run bash "$STRESS" run http://localhost -c 0
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
}

@test "stress rejects invalid duration" {
  run bash "$STRESS" run http://localhost -d 10x
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
}

@test "stress rejects option-like value for threads" {
  run bash "$STRESS" run http://localhost -t "-c5"
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
}

@test "stress external host without --yes and without y cancels" {
  run bash "$STRESS" run https://example.com/x <<< "n"
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
  run bash "$STRESS" run https://example.com/x < /dev/null
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
}

@test "stress external host runs when confirmed with y" {
  run bash "$STRESS" run https://example.com/x <<< "y"
  [[ "$status" -eq 0 ]]
  [[ "$(cat "$WRK_LOG")" == *"https://example.com/x"* ]]
}

@test "stress external host runs with --yes" {
  run bash "$STRESS" run https://example.com/x -t 2 -c 10 -d 5s --yes < /dev/null
  [[ "$status" -eq 0 ]]
  [[ "$(cat "$WRK_LOG")" == "-t2 -c10 -d5s https://example.com/x" ]]
}

@test "stress quick accepts --yes" {
  run bash "$STRESS" quick https://example.com --yes < /dev/null
  [[ "$status" -eq 0 ]]
  [[ -e "$WRK_LOG" ]]
}

@test "stress localhost runs without prompt" {
  run bash "$STRESS" run http://localhost:8080/health < /dev/null
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"wrk-stub"* ]]
}

@test "stress private and .local hosts run without prompt" {
  for u in http://127.0.0.1 http://10.1.2.3 http://192.168.0.5:80 http://172.20.0.1 "http://[::1]:8000" http://box.local/x; do
    run bash "$STRESS" run "$u" < /dev/null
    [[ "$status" -eq 0 ]]
  done
}

@test "stress treats userinfo trick as external host" {
  run bash "$STRESS" run http://localhost@example.com/ < /dev/null
  [[ "$status" -ne 0 ]]
  [[ ! -e "$WRK_LOG" ]]
}

@test "stress 172.32 is external" {
  run bash "$STRESS" run http://172.32.0.1 < /dev/null
  [[ "$status" -ne 0 ]]
}

@test "stress help does not install wrk" {
  export PATH="/usr/bin:/bin"
  run bash "$STRESS" help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"--yes"* ]]
  [[ "$output" != *"Installing"* ]]
}
