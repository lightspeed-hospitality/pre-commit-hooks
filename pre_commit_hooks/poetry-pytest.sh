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

# If validation fails, tell Git to stop and provide error message. Otherwise, continue.
cd $PWD && poetry install -v && poetry run pytest -vv
