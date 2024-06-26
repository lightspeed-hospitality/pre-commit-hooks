#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

_ORG_SLUG="github/lightspeed-hospitality"

function usage {
    echo "usage: [paths] [-h] [-o organization]"
    echo "  -h      display help"
    echo "  -o      organization slug (default: github/lightspeed-hospitality), used when a config depends on private orbs"
    exit 1
}

positional_args=()
while [ $OPTIND -le "$#" ]
do
    if getopts o:h option
    then
        case $option
        in
            h) usage;;
            o) _ORG_SLUG="${OPTARG}";;
        esac
    else
        positional_args+=("${!OPTIND}")
        ((OPTIND++))
    fi
done


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

for path in "${positional_args[@]}"
do

  cmdArgs=('--skip-update-check' 'config' 'validate' '-c' "${path}")
  if [ -n "${_ORG_SLUG}" ]; then
    cmdArgs+=('-o' "${_ORG_SLUG}")
  fi

  if ! eMSG=$(circleci "${cmdArgs[@]}" 2>&1); then
    if [[ ${eMSG} =~ "Cannot find" ]] || [[ ${eMSG} =~ "Permission denied" ]]; then
      echo "This config probably uses private orbs, please run 'circleci setup' and provide your token."
    fi
    echo "CircleCI Configuration Failed Validation."
    echo "${eMSG}"
    exit 1
  fi

done
