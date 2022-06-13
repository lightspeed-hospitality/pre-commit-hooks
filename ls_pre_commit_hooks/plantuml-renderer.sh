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

changed_files=0
for puml_file in "${@}"; do
  FILEDIR="${puml_file%/*}/images"
  FILENAME="${puml_file##*/}"
  SVG_FILE="$FILEDIR/${FILENAME%.*}.svg"

  plantuml -tsvg "$puml_file" -o "images"
  echo "" >> $SVG_FILE # add new line for tidy-xml conflict

  # For new svg file, use `-N` to add the untracked file to unstaged, thus it can be checked at git diff
  git add -N "$SVG_FILE"

  # Check if the svg file is dirty in the git unstaged changes
  if ! git diff --quiet -- "$SVG_FILE" ; then
    changed_files=$((changed_files+1))
  fi
done

# Exit with non-zero code if any of the svg files was changed
exit $changed_files
