#!/usr/bin/env bash

if ! command -v tidy &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install tidy-html5
  else
    >&2 echo 'tidy command not found. Get tidy from https://www.html-tidy.org/.'
  fi
  exit 1
fi

tidy_config=$(mktemp)
echo "indent: auto" >> $tidy_config
echo "indent-spaces: 4" >> $tidy_config
echo "output-xml: yes" >> $tidy_config
echo "input-xml: yes" >> $tidy_config
# Not sure if it should be limitless?
echo "wrap: 0" >> $tidy_config
echo "wrap-attributes: yes" >> $tidy_config
echo "indent-attributes: yes" >> $tidy_config
echo "vertical-space: yes" >> $tidy_config

for xml_file in "${@}"; do
  tidy -quiet -config $tidy_config -o "$xml_file" "$xml_file"
done
