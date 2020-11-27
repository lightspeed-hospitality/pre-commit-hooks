#!/bin/bash -e

# do not run in Circle CI
if [[ -n $CIRCLECI ]]; then
  echo "Only to be executed locally, as a pre-commit hook."
  exit 0;
fi

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

echo 'Begin circleci config packing'

if ! command -v circleci &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install circleci
  else
    >&2 echo 'circleci command not found. See https://circleci.com/docs/2.0/local-cli/ for installation instructions.'
  fi
  exit 1
fi

circleci --skip-update-check config pack .circleci/config > .circleci/config.yml
