#!/usr/bin/env bash

if [[ -n $CIRCLECI ]]; then
 echo "Only to be executed locally, as a pre-commit hook."
 exit 0;
fi

if ! command -v plantuml &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install plantuml
  else
    >&2 echo 'plantuml cannot be installed with brew. Get plantuml from https://plantuml.com/download.'
  fi
fi

for puml_file in "${@}"; do
  plantuml -tsvg "$puml_file" -o "images"
  FILEDIR="${puml_file%/*}/images"
  FILENAME="${puml_file##*/}"
  SVG_FILENAME="${FILENAME%.*}.svg"

  echo "$FILEDIR/$SVG_FILENAME"
  git add "$FILEDIR/$SVG_FILENAME"
done
