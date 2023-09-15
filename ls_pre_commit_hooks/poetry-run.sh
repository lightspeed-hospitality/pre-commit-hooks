#!/bin/bash

set -e
set -o pipefail
set -u
set -x

if ! [ -x "$(command -v poetry)" ]; then
  echo 'poetry command not found'
  echo 'See https://python-poetry.org/docs/#installation for installation instructions.'
  exit 1
fi

poetry run --no-ansi --no-interaction -- "$@"
