#!/usr/bin/env bash

_CIRCLECI_CLI_VERSION="1.14.0"
_CIRCLECI_RELEASE_BASE="https://github.com/CircleCI-Public/circleci-cli/releases/download/v${_CIRCLECI_CLI_VERSION}"

function is_circleci_v1 {
  command -v circleci >/dev/null 2>&1 \
    && circleci version 2>/dev/null | grep -Eq '^circleci 1(\.|[[:space:]])'
}

function circleci_release_asset {
  case "$1/$2" in
    darwin/amd64) printf '%s\n' "circleci-cli_${_CIRCLECI_CLI_VERSION}_darwin_amd64.tar.gz" ;;
    darwin/arm64) printf '%s\n' "circleci-cli_${_CIRCLECI_CLI_VERSION}_darwin_arm64.tar.gz" ;;
    linux/amd64) printf '%s\n' "circleci-cli_${_CIRCLECI_CLI_VERSION}_linux_amd64.tar.gz" ;;
    linux/arm64) printf '%s\n' "circleci-cli_${_CIRCLECI_CLI_VERSION}_linux_arm64.tar.gz" ;;
    *) return 1 ;;
  esac
}

function circleci_release_sha256 {
  # Digests are pinned from CircleCI's v1.14.0 checksums release asset.
  case "$1/$2" in
    darwin/amd64) printf '%s\n' "a295caffc6ce879179f394c21df7775cbe286ad5bfe0fc003903d84065989145" ;;
    darwin/arm64) printf '%s\n' "ae3a9d0399bafc9169a6fca7bced2e0a35a51e1e870d6efc56955cb99b29941b" ;;
    linux/amd64) printf '%s\n' "5d0227b38ad65b2fb23ef1fbebfe98851c77102f76a72df2273eacca941665c4" ;;
    linux/arm64) printf '%s\n' "d1cfb57078bcd0d3ff4c20f2765574e1f1022a3ba41cf164acd36a521a7a35f0" ;;
    *) return 1 ;;
  esac
}

function circleci_verify_sha256 {
  local expected_sha256="$1"
  local archive="$2"

  if command -v shasum >/dev/null 2>&1; then
    if printf '%s  %s\n' "${expected_sha256}" "${archive}" | shasum -a 256 -c - >/dev/null; then
      return 0
    fi
  elif command -v sha256sum >/dev/null 2>&1; then
    if printf '%s  %s\n' "${expected_sha256}" "${archive}" | sha256sum -c - >/dev/null; then
      return 0
    fi
  else
    >&2 echo "Neither shasum nor sha256sum is available to verify the CircleCI CLI download."
    return 1
  fi

  >&2 echo "Checksum verification failed for ${archive}."
  return 1
}

function install_circleci_cli {
  local system architecture os arch asset checksum url install_dir tmp_dir archive

  system="$(uname -s 2>/dev/null || true)"
  case "${system}" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *)
      >&2 echo "Automatic CircleCI CLI installation is unsupported on ${system:-unknown}. Install CircleCI CLI ${_CIRCLECI_CLI_VERSION} manually."
      return 1
      ;;
  esac

  architecture="$(uname -m 2>/dev/null || true)"
  case "${architecture}" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      >&2 echo "Automatic CircleCI CLI installation is unsupported on ${architecture:-unknown}. Install CircleCI CLI ${_CIRCLECI_CLI_VERSION} manually."
      return 1
      ;;
  esac

  if ! asset="$(circleci_release_asset "${os}" "${arch}")"; then
    >&2 echo "No CircleCI CLI ${_CIRCLECI_CLI_VERSION} release is available for ${os}/${arch}."
    return 1
  fi
  if ! checksum="$(circleci_release_sha256 "${os}" "${arch}")"; then
    >&2 echo "No pinned CircleCI CLI ${_CIRCLECI_CLI_VERSION} checksum is available for ${os}/${arch}."
    return 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    >&2 echo "curl is required to download CircleCI CLI ${_CIRCLECI_CLI_VERSION}."
    return 1
  fi
  if ! command -v tar >/dev/null 2>&1; then
    >&2 echo "tar is required to extract CircleCI CLI ${_CIRCLECI_CLI_VERSION}."
    return 1
  fi

  if [[ -n "${CIRCLECI_INSTALL_DIR:-}" ]]; then
    install_dir="${CIRCLECI_INSTALL_DIR}"
  elif [[ -n "${HOME:-}" ]]; then
    install_dir="${HOME}/.local/bin"
  else
    >&2 echo "HOME is required to install CircleCI CLI ${_CIRCLECI_CLI_VERSION}."
    return 1
  fi

  if ! tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/circleci-cli.XXXXXX")"; then
    >&2 echo "Could not create a temporary directory for CircleCI CLI installation."
    return 1
  fi

  archive="${tmp_dir}/${asset}"
  url="${_CIRCLECI_RELEASE_BASE}/${asset}"
  echo "Installing CircleCI CLI ${_CIRCLECI_CLI_VERSION} for ${os}/${arch}..."

  if ! curl -fsSL --output "${archive}" "${url}"; then
    rm -rf "${tmp_dir}"
    >&2 echo "Failed to download CircleCI CLI ${_CIRCLECI_CLI_VERSION} from ${url}."
    return 1
  fi
  if ! circleci_verify_sha256 "${checksum}" "${archive}"; then
    rm -rf "${tmp_dir}"
    return 1
  fi
  if ! tar -xzf "${archive}" -C "${tmp_dir}" || [[ ! -x "${tmp_dir}/circleci" ]]; then
    rm -rf "${tmp_dir}"
    >&2 echo "Failed to extract the CircleCI CLI binary from ${asset}."
    return 1
  fi
  if ! mkdir -p "${install_dir}" || ! install -m 0755 "${tmp_dir}/circleci" "${install_dir}/circleci"; then
    rm -rf "${tmp_dir}"
    >&2 echo "Failed to install CircleCI CLI into ${install_dir}."
    return 1
  fi

  rm -rf "${tmp_dir}"
  PATH="${install_dir}:${PATH:-}"
  export PATH
  hash -r 2>/dev/null || true

  if [[ "$(circleci version 2>/dev/null || true)" != "circleci ${_CIRCLECI_CLI_VERSION}"* ]]; then
    >&2 echo "Installed the pinned CircleCI CLI archive, but the installed binary did not report version ${_CIRCLECI_CLI_VERSION}."
    return 1
  fi
}

function ensure_circleci_cli {
  local install_dir current_version

  if [[ -n "${CIRCLECI_INSTALL_DIR:-}" ]]; then
    install_dir="${CIRCLECI_INSTALL_DIR}"
  elif [[ -n "${HOME:-}" ]]; then
    install_dir="${HOME}/.local/bin"
  else
    install_dir=""
  fi

  if ! command -v circleci >/dev/null 2>&1 && [[ -n "${install_dir}" && -x "${install_dir}/circleci" ]]; then
    PATH="${install_dir}:${PATH:-}"
    export PATH
    hash -r 2>/dev/null || true
  fi

  if command -v circleci >/dev/null 2>&1; then
    current_version="$(circleci version 2>/dev/null || true)"
    if [[ "${current_version}" != "circleci ${_CIRCLECI_CLI_VERSION}"* ]]; then
      >&2 echo "Warning: using existing CircleCI CLI (${current_version:-unknown}); the pinned installer version is ${_CIRCLECI_CLI_VERSION}. The existing CLI will not be replaced."
    fi
    return 0
  fi

  install_circleci_cli
}
