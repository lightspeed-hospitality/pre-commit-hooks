#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# shellcheck source=ls_pre_commit_hooks/circleci-cli.sh
source "${BASH_SOURCE[0]%/*}/circleci-cli.sh"

_PATH="${1:-.circleci/config.yml}"

# Do not run in CircleCI.
if [[ -n "${CI:-}" ]]; then
  echo "Skipping config packing when running in CI."
  exit 0
fi

DEBUG="${DEBUG:=0}"
[[ "${DEBUG}" -eq 1 ]] && set -o xtrace

echo "Begin circleci config packing"

ensure_circleci_v1

# Pack into a temporary file so a failed pack cannot replace a valid config.
tmp_path="$(mktemp "${_PATH}.tmp.XXXXXX")"
trap 'rm -f "${tmp_path}"' EXIT

if [[ -e "${_PATH}" ]]; then
  cp -p "${_PATH}" "${tmp_path}"
fi

circleci config pack .circleci > "${tmp_path}"
mv "${tmp_path}" "${_PATH}"
trap - EXIT
