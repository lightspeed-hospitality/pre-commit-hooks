#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Org slug from `circleci org list` for Lightspeed Hospitality
# (id f941771b-a958-44f8-bd3c-a7d38904a4c8).
_ORG_SLUG="gh/lightspeed-hospitality"
_CIRCLECI_FORMULA="circleci-public/circleci/circleci@next"

function usage {
  echo "usage: [paths] [-h] [-o organization]"
  echo "  -h      display help"
  echo "  -o      organization slug (default: ${_ORG_SLUG}), used when a config depends on private orbs"
  exit 1
}

positional_args=()
while [ "${OPTIND}" -le "$#" ]; do
  if getopts o:h option; then
    case "${option}" in
      h) usage ;;
      o) _ORG_SLUG="${OPTARG}" ;;
    esac
  else
    positional_args+=("${!OPTIND}")
    OPTIND=$((OPTIND + 1))
  fi
done

DEBUG="${DEBUG:=0}"
[[ "${DEBUG}" -eq 1 ]] && set -o xtrace

if [[ -n "${CI:-}" ]]; then
  echo "Skipping config validation when running in CI."
  exit 0
fi

echo "Begin circleci config validation"

if [[ ${#positional_args[@]} -eq 0 ]]; then
  >&2 echo "No config paths provided."
  usage
fi

if ! command -v circleci &>/dev/null || ! circleci version 2>/dev/null | grep -q '^circleci 1\.'; then
  if ! command -v brew &>/dev/null; then
    >&2 echo "Homebrew is required to install the supported CircleCI CLI: ${_CIRCLECI_FORMULA}."
    >&2 echo "See https://cli.circleci.com/ for other install options."
    exit 1
  fi
  echo "Installing supported CircleCI CLI (${_CIRCLECI_FORMULA})..."
  brew install "${_CIRCLECI_FORMULA}"
fi

for path in "${positional_args[@]}"; do
  cmdArgs=('--quiet' 'config' 'validate' '--config' "${path}" '--org' "${_ORG_SLUG}")

  if ! eMSG=$(circleci "${cmdArgs[@]}" 2>&1); then
    if [[ ${eMSG} =~ "Cannot find" ]] || [[ ${eMSG} =~ "Permission denied" ]]; then
      echo "This config probably uses private orbs, please run 'circleci auth login' or set CIRCLE_TOKEN."
    fi
    echo "CircleCI Configuration Failed Validation."
    echo "${eMSG}"
    exit 1
  fi

  echo "OK: ${path}"
done
