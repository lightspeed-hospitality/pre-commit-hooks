#!/bin/bash -e

# do not run in Circle CI
if [[ -n $CIRCLECI ]]; then
  echo "Only to be executed locally, as a pre-commit hook."
  exit 0;
fi

if ! [ -x "$(command -v poetry)" ]; then
  echo 'poetry command not found'
  echo 'See https://python-poetry.org/docs/#installation for installation instructions.'
  exit 1
fi

_PATH="$PWD/$1"
echo "Running pytest in $_PATH"
cd $PWD && poetry install -v && poetry run pytest "${_PATH}" -vv
