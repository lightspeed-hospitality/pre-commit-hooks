#!/bin/bash

set -e
set -o pipefail
set -u
set -x

# do not run in Circle CI
if [[ -n "${CIRCLECI:-}" ]]; then
  echo "Only to be executed locally, as a pre-commit hook."
  exit 0;
fi

if ! [ -x "$(command -v poetry)" ]; then
  echo 'poetry command not found'
  echo 'See https://python-poetry.org/docs/#installation for installation instructions.'
  exit 1
fi

echo "Running pytest in $PWD"
poetry install --no-ansi --no-interaction -v
poetry run pytest -vv
