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
  FILENAME="${puml_file##*/}"
  ORIDIR="${puml_file%/*}"

  TMPDIR="_tmp_"

  plantuml -tsvg "$puml_file" -o "${TMPDIR}"
  TMPDIR="${ORIDIR}/${TMPDIR}"
  SVG_TMPFILE="${TMPDIR}/${FILENAME%.*}.svg"
  echo "" >> $SVG_TMPFILE # add new line for tidy-xml conflict


  OUTPUTDIR="${ORIDIR}/images"
  SVG_FILE="$OUTPUTDIR/${FILENAME%.*}.svg"

  # Check if existing svg file exist
  if test -f "$SVG_FILE"; then
    # Check if the existing svg file is identical with the generated
    if ! git diff --quiet --no-index "$SVG_TMPFILE" "$SVG_FILE" ; then
      mv -f "$SVG_TMPFILE" "$OUTPUTDIR"
      # if it is not identical, mark as changed
      changed_files=$((changed_files+1))
    else
      rm -f "$SVG_TMPFILE" "$OUTPUTDIR"
    fi
  else
    # if no existing svg file exist then move and stage it.
    mv -f "$SVG_TMPFILE" "$OUTPUTDIR"
    echo "New svg gile generated, and staged. File: $SVG_FILE"
    git add $SVG_FILE
    changed_files=$((changed_files+1))
  fi
  rm -d $TMPDIR
done

# Exit with non-zero code if any of the svg files was changed
echo "Total changed files: $changed_files."
exit $changed_files
