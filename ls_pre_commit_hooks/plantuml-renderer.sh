#!/usr/bin/env bash

if ! command -v plantuml &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install plantuml
  else
    >&2 echo 'plantuml command not found. See https://plantuml.com/download for installation instructions.'
  fi
  exit 1
fi

for puml_file in "${@}"; do
  echo "${@}"
  plantuml -tsvg "${@}" -o "images" -v
done
