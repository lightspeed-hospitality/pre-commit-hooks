#!/usr/bin/env bats

# Each Bats test runs in a subshell, so per-test environment overrides are intentional.
# shellcheck disable=SC2030,SC2031

setup() {
  ROOT_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/circleci-cli-tests.XXXXXX")"
  TEST_BIN="${TEST_TMPDIR}/bin"
  mkdir -p "${TEST_BIN}"

  export PATH="${TEST_BIN}:/usr/bin:/bin"
  export CIRCLECI_TEST_VERSION=""
  export CIRCLECI_TEST_ARGS_LOG="${TEST_TMPDIR}/circleci-args"
  export CIRCLECI_TEST_BREW_PREFIX="${TEST_TMPDIR}/brew"
  export CIRCLECI_TEST_BREW_LOG="${TEST_TMPDIR}/brew-args"

  source "${ROOT_DIR}/ls_pre_commit_hooks/circleci-cli.sh"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

write_fake_circleci() {
  local destination="$1"
  mkdir -p "$(dirname "${destination}")"
  cat >"${destination}" <<'EOF'
#!/bin/sh
if [ "$1" = version ]; then
  printf '%s\n' "${CIRCLECI_TEST_VERSION}"
  exit 0
fi
if [ -n "${CIRCLECI_TEST_ARGS_LOG:-}" ]; then
  printf '<%s>\n' "$@" >> "${CIRCLECI_TEST_ARGS_LOG}"
fi
if [ "${CIRCLECI_TEST_FAIL:-0}" = 1 ]; then
  printf '%s\n' "${CIRCLECI_TEST_ERROR}" >&2
  exit 1
fi
exit 0
EOF
  chmod +x "${destination}"
}

stub_homebrew_install() {
  cat >"${TEST_BIN}/brew" <<'EOF'
#!/bin/sh
case "$1" in
  install)
    printf '%s\n' "$*" > "${CIRCLECI_TEST_BREW_LOG}"
    write_target="${CIRCLECI_TEST_BREW_PREFIX}/bin/circleci"
    mkdir -p "$(dirname "${write_target}")"
    cat > "${write_target}" <<'CIRCLECI'
#!/bin/sh
if [ "$1" = version ]; then
  printf '%s\n' 'circleci 1.14.0 (test)'
fi
CIRCLECI
    chmod +x "${write_target}"
    ;;
  --prefix) printf '%s\n' "${CIRCLECI_TEST_BREW_PREFIX}" ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "${TEST_BIN}/brew"
}

@test "an existing CLI is kept and warns instead of being replaced" {
  export CIRCLECI_TEST_VERSION='0.1.34283+28a3be8 (release)'
  write_fake_circleci "${TEST_BIN}/circleci"
  stub_homebrew_install

  run ensure_circleci_cli

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'using existing CircleCI CLI'* ]]
  [[ "${output}" == *'will not be replaced'* ]]
  [ ! -e "${CIRCLECI_TEST_BREW_LOG}" ]
}

@test "a missing CLI is installed with the official Homebrew command" {
  stub_homebrew_install

  ensure_circleci_cli

  [ "$(cat "${CIRCLECI_TEST_BREW_LOG}")" = 'install circleci' ]
  [ -x "${CIRCLECI_TEST_BREW_PREFIX}/bin/circleci" ]
  [ "$(circleci version)" = 'circleci 1.14.0 (test)' ]
}

@test "a Homebrew install failure is reported" {
  cat >"${TEST_BIN}/brew" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "${TEST_BIN}/brew"

  run ensure_circleci_cli

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'Failed to install CircleCI CLI with Homebrew.'* ]]
}

@test "a missing Homebrew installation fails with the official install guidance" {
  run ensure_circleci_cli

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'Homebrew is required'* ]]
  [[ "${output}" == *'https://cli.circleci.com/'* ]]
}

@test "legacy validation uses flags supported by the stable CLI" {
  export CIRCLECI_TEST_VERSION='0.1.34283+28a3be8 (release)'
  unset CI
  write_fake_circleci "${TEST_BIN}/circleci"

  run "${ROOT_DIR}/ls_pre_commit_hooks/circleci-config-validate.sh" 'config.yml'

  [ "${status}" -eq 0 ]
  grep -Fx '<config>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<validate>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<--skip-update-check>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<--config>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<--org-slug>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<gh/lightspeed-hospitality>' "${CIRCLECI_TEST_ARGS_LOG}"
  run grep -Fx '<--quiet>' "${CIRCLECI_TEST_ARGS_LOG}"
  [ "${status}" -ne 0 ]
  run grep -Fx '<--org>' "${CIRCLECI_TEST_ARGS_LOG}"
  [ "${status}" -ne 0 ]
}

@test "1.x validation uses flags supported by the current CLI" {
  export CIRCLECI_TEST_VERSION='circleci 1.14.0 (test)'
  unset CI
  write_fake_circleci "${TEST_BIN}/circleci"

  run "${ROOT_DIR}/ls_pre_commit_hooks/circleci-config-validate.sh" 'config.yml'

  [ "${status}" -eq 0 ]
  grep -Fx '<--quiet>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<config>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<validate>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<--config>' "${CIRCLECI_TEST_ARGS_LOG}"
  grep -Fx '<--org>' "${CIRCLECI_TEST_ARGS_LOG}"
  run grep -Fx '<--skip-update-check>' "${CIRCLECI_TEST_ARGS_LOG}"
  [ "${status}" -ne 0 ]
}

@test "validation failures preserve CircleCI's diagnostic" {
  export CIRCLECI_TEST_VERSION='0.1.34283+28a3be8 (release)'
  export CIRCLECI_TEST_FAIL=1
  export CIRCLECI_TEST_ERROR='pipeline config is invalid at line 3'
  unset CI
  write_fake_circleci "${TEST_BIN}/circleci"

  run "${ROOT_DIR}/ls_pre_commit_hooks/circleci-config-validate.sh" 'config.yml'

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'CircleCI Configuration Failed Validation.'* ]]
  [[ "${output}" == *'pipeline config is invalid at line 3'* ]]
}
