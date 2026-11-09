#!/usr/bin/env bats

# Each Bats test runs in a subshell, so per-test environment overrides are intentional.
# shellcheck disable=SC2030,SC2031

setup() {
  ROOT_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "${TEST_BIN}"

  export PATH="${TEST_BIN}:/usr/bin:/bin"
  export CIRCLECI_INSTALL_DIR="${BATS_TEST_TMPDIR}/install"
  export CIRCLECI_TEST_OS="Darwin"
  export CIRCLECI_TEST_ARCH="arm64"
  export CIRCLECI_TEST_VERSION=""
  export CIRCLECI_TEST_URL_LOG="${BATS_TEST_TMPDIR}/download-url"

  cat > "${TEST_BIN}/uname" <<'EOF'
#!/bin/sh
case "$1" in
  -s) printf '%s\n' "${CIRCLECI_TEST_OS}" ;;
  -m) printf '%s\n' "${CIRCLECI_TEST_ARCH}" ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "${TEST_BIN}/uname"

  cat > "${TEST_BIN}/curl" <<'EOF'
#!/bin/sh
exit 99
EOF
  chmod +x "${TEST_BIN}/curl"

  source "${ROOT_DIR}/ls_pre_commit_hooks/circleci-cli.sh"
}

write_fake_circleci() {
  cat > "${TEST_BIN}/circleci" <<'EOF'
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
  chmod +x "${TEST_BIN}/circleci"
}

stub_release_download() {
  local archive="$1"

  cat > "${TEST_BIN}/curl" <<'EOF'
#!/bin/sh
output=
url=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      output="$2"
      shift 2
      ;;
    https://*)
      url="$1"
      shift
      ;;
    *) shift ;;
  esac
done
printf '%s\n' "${url}" > "${CIRCLECI_TEST_URL_LOG}"
if [ "${CIRCLECI_TEST_CURL_FAIL:-0}" = 1 ]; then
  exit 22
fi
cp "${CIRCLECI_TEST_ARCHIVE}" "${output}"
EOF
  chmod +x "${TEST_BIN}/curl"
  export CIRCLECI_TEST_ARCHIVE="${archive}"
  export CIRCLECI_TEST_URL_LOG="${BATS_TEST_TMPDIR}/download-url"
}

make_test_archive() {
  local fixture_dir="${BATS_TEST_TMPDIR}/fixture"
  mkdir -p "${fixture_dir}"
  cat > "${fixture_dir}/circleci" <<'EOF'
#!/bin/sh
if [ "$1" = version ]; then
  printf '%s\n' 'circleci 1.14.0 (test)'
fi
EOF
  chmod +x "${fixture_dir}/circleci"
  tar -czf "${BATS_TEST_TMPDIR}/circleci-fixture.tar.gz" -C "${fixture_dir}" circleci
}

@test "an existing pinned CLI is kept without warning or install" {
  export CIRCLECI_TEST_VERSION='circleci 1.14.0 (test)'
  write_fake_circleci

  run ensure_circleci_cli

  [ "${status}" -eq 0 ]
  [[ "${output}" != *'Warning:'* ]]
  [ ! -e "${CIRCLECI_INSTALL_DIR}/circleci" ]
}

@test "an existing legacy CLI is kept and warns instead of installing" {
  export CIRCLECI_TEST_OS='Linux'
  export CIRCLECI_TEST_VERSION='0.1.34283+28a3be8 (release)'
  write_fake_circleci

  run ensure_circleci_cli

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'existing CircleCI CLI'* ]]
  [[ "${output}" == *'will not be replaced'* ]]
  [ ! -e "${CIRCLECI_INSTALL_DIR}/circleci" ]
}

@test "a different 1.x CLI is kept and warns instead of installing" {
  export CIRCLECI_TEST_VERSION='circleci 1.13.0 (test)'
  write_fake_circleci

  run ensure_circleci_cli

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'pinned installer version is 1.14.0'* ]]
  [ ! -e "${CIRCLECI_INSTALL_DIR}/circleci" ]
}

@test "pins official release assets and published archive checksums" {
  [ "$(circleci_release_asset darwin amd64)" = 'circleci-cli_1.14.0_darwin_amd64.tar.gz' ]
  [ "$(circleci_release_sha256 darwin amd64)" = 'a295caffc6ce879179f394c21df7775cbe286ad5bfe0fc003903d84065989145' ]
  [ "$(circleci_release_asset darwin arm64)" = 'circleci-cli_1.14.0_darwin_arm64.tar.gz' ]
  [ "$(circleci_release_sha256 darwin arm64)" = 'ae3a9d0399bafc9169a6fca7bced2e0a35a51e1e870d6efc56955cb99b29941b' ]
  [ "$(circleci_release_asset linux amd64)" = 'circleci-cli_1.14.0_linux_amd64.tar.gz' ]
  [ "$(circleci_release_sha256 linux amd64)" = '5d0227b38ad65b2fb23ef1fbebfe98851c77102f76a72df2273eacca941665c4' ]
  [ "$(circleci_release_asset linux arm64)" = 'circleci-cli_1.14.0_linux_arm64.tar.gz' ]
  [ "$(circleci_release_sha256 linux arm64)" = 'd1cfb57078bcd0d3ff4c20f2765574e1f1022a3ba41cf164acd36a521a7a35f0' ]
}

@test "a missing CLI is installed from its pinned archive without fetching a checksum manifest" {
  make_test_archive
  stub_release_download "${BATS_TEST_TMPDIR}/circleci-fixture.tar.gz"
  CIRCLECI_TEST_EXPECTED_CHECKSUM="$(shasum -a 256 "${CIRCLECI_TEST_ARCHIVE}" | cut -d ' ' -f1)"
  export CIRCLECI_TEST_EXPECTED_CHECKSUM
  # The installer calls this helper indirectly; use a real digest for the fixture archive.
  # shellcheck disable=SC2329
  circleci_release_sha256() { printf '%s\n' "${CIRCLECI_TEST_EXPECTED_CHECKSUM}"; }

  run ensure_circleci_cli

  [ "${status}" -eq 0 ]
  [ -x "${CIRCLECI_INSTALL_DIR}/circleci" ]
  [[ "$(cat "${CIRCLECI_TEST_URL_LOG}")" == *'/v1.14.0/circleci-cli_1.14.0_darwin_arm64.tar.gz' ]]
  [[ "$(cat "${CIRCLECI_TEST_URL_LOG}")" != *'checksums.txt'* ]]
  [ "$("${CIRCLECI_INSTALL_DIR}/circleci" version)" = 'circleci 1.14.0 (test)' ]
}

@test "a missing CLI on Linux selects the matching pinned release asset" {
  export CIRCLECI_TEST_OS='Linux'
  export CIRCLECI_TEST_ARCH='x86_64'
  make_test_archive
  stub_release_download "${BATS_TEST_TMPDIR}/circleci-fixture.tar.gz"
  CIRCLECI_TEST_EXPECTED_CHECKSUM="$(shasum -a 256 "${CIRCLECI_TEST_ARCHIVE}" | cut -d ' ' -f1)"
  export CIRCLECI_TEST_EXPECTED_CHECKSUM
  circleci_release_sha256() { printf '%s\n' "${CIRCLECI_TEST_EXPECTED_CHECKSUM}"; }

  run ensure_circleci_cli

  [ "${status}" -eq 0 ]
  [[ "$(cat "${CIRCLECI_TEST_URL_LOG}")" == *'/v1.14.0/circleci-cli_1.14.0_linux_amd64.tar.gz' ]]
  [ -x "${CIRCLECI_INSTALL_DIR}/circleci" ]
}

@test "a failed download does not install a CLI" {
  make_test_archive
  stub_release_download "${BATS_TEST_TMPDIR}/circleci-fixture.tar.gz"
  export CIRCLECI_TEST_CURL_FAIL=1

  run ensure_circleci_cli

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'Failed to download CircleCI CLI'* ]]
  [ ! -e "${CIRCLECI_INSTALL_DIR}/circleci" ]
}

@test "a missing CLI is not installed when archive checksum verification fails" {
  make_test_archive
  stub_release_download "${BATS_TEST_TMPDIR}/circleci-fixture.tar.gz"

  run ensure_circleci_cli

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'Checksum verification failed'* ]]
  [ ! -e "${CIRCLECI_INSTALL_DIR}/circleci" ]
}

@test "unsupported platforms fail before attempting a download" {
  export CIRCLECI_TEST_OS='FreeBSD'

  run ensure_circleci_cli

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'unsupported on FreeBSD'* ]]
  [ ! -e "${CIRCLECI_TEST_URL_LOG}" ]
}

@test "legacy validation uses flags supported by the stable CLI" {
  export CIRCLECI_TEST_VERSION='0.1.34283+28a3be8 (release)'
  export CIRCLECI_TEST_ARGS_LOG="${BATS_TEST_TMPDIR}/circleci-args"
  unset CI
  write_fake_circleci

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

@test "1.x validation uses flags supported by the preview CLI" {
  export CIRCLECI_TEST_VERSION='circleci 1.14.0 (test)'
  export CIRCLECI_TEST_ARGS_LOG="${BATS_TEST_TMPDIR}/circleci-args"
  unset CI
  write_fake_circleci

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
  write_fake_circleci

  run "${ROOT_DIR}/ls_pre_commit_hooks/circleci-config-validate.sh" 'config.yml'

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'CircleCI Configuration Failed Validation.'* ]]
  [[ "${output}" == *'pipeline config is invalid at line 3'* ]]
}
