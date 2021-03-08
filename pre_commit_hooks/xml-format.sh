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
cat <<EOF > $tidy_config
indent: auto
indent-spaces: 4
output-xml: yes
input-xml: yes
wrap: 0
wrap-attributes: yes
indent-attributes: yes
vertical-space: yes
EOF

for xml_file in "${@}"; do
  tidy -quiet -config $tidy_config -o "$xml_file" "$xml_file"
done
