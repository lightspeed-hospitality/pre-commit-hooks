#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

_PATH=$1
_ORG=$2
if [ -z "${_PATH}" ]; then
  _PATH=.circleci/config.yml
fi

if [ -z "${_ORG}" ]; then
  _ORG=github/lightspeed-hospitality
fi

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

if [[ -n "${CI:-}" ]]; then
  echo "Skipping config validation when running in CI."
  exit 0
fi

echo 'Begin circleci config validation'

if ! command -v circleci &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install circleci
  else
    >&2 echo 'circleci command not found. See https://circleci.com/docs/2.0/local-cli/ for installation instructions.'
  fi
  exit 1
fi

if ! eMSG=$(circleci --skip-update-check config validate --org-slug "${_ORG}" -c "${_PATH}"); then
  if [[ ${eMSG} =~ "Cannot find" ]] || [[ ${eMSG} =~ "Permission denied" ]]; then
    echo "This config probably uses private orbs, please run 'circleci setup' and provide your token."
  fi
  echo "CircleCI Configuration Failed Validation."
  echo ${eMSG}
  exit 1
fi
