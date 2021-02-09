#!/usr/bin/env bash
# Original: https://github.com/Yelp/detect-secrets

set -eu

readonly DEBUG=${DEBUG:-unset}
if [ "${DEBUG}" != unset ]; then
  set -x
fi

if ! command -v detect-secrets >/dev/null 2>&1; then
  if command -v pip3 &>/dev/null; then
    pip3 install detect-secrets==0.14.3
  else
    >&2 echo 'This check needs detect-secrets from https://github.com/Yelp/detect-secrets or pip3 install detect-secrets'
    exit 1
  fi
fi

readonly cmd=(detect-secrets "$@")
echo "[RUN] ${cmd[@]}"
output="$("${cmd[@]}" 2>&1)"
readonly output

if [ -n "${output}" ]; then
  echo '[FAIL]'
  echo
  echo "${output}"
  echo
  echo 'The above files contain secrets.'
  exit 1
else
  echo '[PASS]'
fi
