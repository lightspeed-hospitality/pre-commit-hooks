#!/bin/bash -e

if ! which -s poetry; then
  echo 'poetry command not found'
  echo 'See https://python-poetry.org/docs/#installation for installation instructions.'
  exit 1
fi

poetry run "$@"
