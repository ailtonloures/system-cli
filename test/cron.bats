#!/usr/bin/env bats

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME" "${BATS_TEST_TMPDIR}/bin"
  export CRON_STATE="${BATS_TEST_TMPDIR}/crontab.state"
  : > "$CRON_STATE"
  cat > "${BATS_TEST_TMPDIR}/bin/crontab" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  -l) [[ -s "$CRON_STATE" ]] && cat "$CRON_STATE"; exit 0 ;;
  -)  data="$(cat)"; printf "%s\n" "$data" > "$CRON_STATE" ;;
esac
STUB
  chmod +x "${BATS_TEST_TMPDIR}/bin/crontab"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  CRON="${BATS_TEST_DIRNAME}/../bin/cron"
}

@test "cron add rejects invalid names" {
  for n in 'a b' 'a.b' 'a;b' 'a*' 'a/b'; do
    run bash "$CRON" add "$n" '0 2 * * *' 'echo hi'
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Invalid name"* ]]
  done
  [[ ! -s "$CRON_STATE" ]]
}

@test "cron remove and update reject invalid names" {
  run bash "$CRON" remove 'a.b'
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid name"* ]]
  run bash "$CRON" update 'a b'
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Invalid name"* ]]
}

@test "cron add accepts valid name and writes label" {
  run bash "$CRON" add my_job-1 '0 2 * * *' 'echo hi'
  [[ "$status" -eq 0 ]]
  grep -qxF '# cron:my_job-1' "$CRON_STATE"
  grep -qxF '0 2 * * * echo hi' "$CRON_STATE"
}

@test "cron add of a is not blocked by existing ab" {
  bash "$CRON" add ab '0 2 * * *' 'echo ab'
  run bash "$CRON" add a '1 2 * * *' 'echo a'
  [[ "$status" -eq 0 ]]
}

@test "cron remove a does not affect ab" {
  bash "$CRON" add ab '0 2 * * *' 'echo ab'
  bash "$CRON" add a '1 2 * * *' 'echo a'
  run bash -c 'echo y | bash "$1" remove a' _ "$CRON"
  [[ "$status" -eq 0 ]]
  grep -qxF '# cron:ab' "$CRON_STATE"
  grep -qxF '0 2 * * * echo ab' "$CRON_STATE"
  ! grep -qxF '# cron:a' "$CRON_STATE"
  ! grep -q 'echo a$' "$CRON_STATE"
}

@test "cron remove of prefix name is not found when only longer exists" {
  bash "$CRON" add ab '0 2 * * *' 'echo ab'
  run bash -c 'echo y | bash "$1" remove a' _ "$CRON"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"not found"* ]]
  grep -qxF '# cron:ab' "$CRON_STATE"
}

@test "cron update only affects the matching job" {
  bash "$CRON" add ab '0 2 * * *' 'echo ab'
  bash "$CRON" add a '1 2 * * *' 'echo a'
  run bash -c 'printf "5 5 * * *\nechoNEW\\\\n\n" | bash "$1" update a' _ "$CRON"
  [[ "$status" -eq 0 ]]
  grep -qxF '0 2 * * * echo ab' "$CRON_STATE"
  grep -qxF '5 5 * * * echoNEW\n' "$CRON_STATE"
  [[ "$(grep -c '^# cron:' "$CRON_STATE")" -eq 2 ]]
}

@test "cron warns on unescaped percent" {
  run bash "$CRON" add p '0 2 * * *' 'date +%F'
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"unescaped '%'"* ]]
  grep -qF 'date +%F' "$CRON_STATE"
}

@test "cron does not warn on escaped percent" {
  run bash "$CRON" add p '0 2 * * *' 'date +\%F'
  [[ "$status" -eq 0 ]]
  [[ "$output" != *"unescaped"* ]]
}
