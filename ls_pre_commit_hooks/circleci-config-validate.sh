#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

_ORG_SLUG="gh/lightspeed-hospitality"

function usage {
    echo "usage: [paths] [-h] [-o organization]"
    echo "  -h      display help"
    echo "  -o      organization slug (default: gh/lightspeed-hospitality), used when a config depends on private orbs"
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

if ! command -v brew &>/dev/null; then
  >&2 echo 'Homebrew is required to install the supported CircleCI CLI: circleci-public/circleci/circleci@next.'
  exit 1
fi

if ! command -v circleci &>/dev/null || ! circleci version 2>/dev/null | grep -q '^circleci 1\.'; then
  brew install circleci-public/circleci/circleci@next
fi

for path in "${positional_args[@]}"
do

  cmdArgs=('--quiet' 'config' 'validate' '--config' "${path}")
  if [ -n "${_ORG_SLUG}" ]; then
    cmdArgs+=('--org' "${_ORG_SLUG}")
  fi

  if ! eMSG=$(circleci "${cmdArgs[@]}" 2>&1); then
    if [[ ${eMSG} =~ "Cannot find" ]] || [[ ${eMSG} =~ "Permission denied" ]]; then
      echo "This config probably uses private orbs, please run 'circleci auth login' or set CIRCLE_TOKEN."
    fi
    echo "CircleCI Configuration Failed Validation."
    echo "${eMSG}"
    exit 1
  fi

done
