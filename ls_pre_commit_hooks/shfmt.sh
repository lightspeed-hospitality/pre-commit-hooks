#!/usr/bin/env bash
# Original: https://github.com/syntaqx/git-hooks
# Forked to auto-install shfmt and give better command suggestions
# Original: https://github.com/jumanjihouse/pre-commit-hooks#shfmt
# Forked to change runtime to /usr/bin/env on win10
set -eu

readonly DEBUG=${DEBUG:-unset}
if [ "${DEBUG}" != unset ]; then
  set -x
fi

if ! command -v shfmt >/dev/null 2>&1; then
  echo "shfmt not found, installing it..."
  if command -v brew &>/dev/null; then
    echo "... using brew"
    brew install shfmt
  elif command -v apt-get &>/dev/null; then
    echo "... using apt-get"
    sudo apt-get -qq update &>/dev/null
    sudo apt-get -qqy install shfmt
  else
    >&2 echo 'This check needs shfmt from https://github.com/mvdan/sh/releases'
    exit 1
  fi
fi

readonly cmd=(shfmt "$@")
echo "[RUN] ${cmd[@]}"
output="$("${cmd[@]}" 2>&1)"
readonly output

if [ -n "${output}" ]; then
  echo '[FAIL]'
  echo
  echo "${output}"
  echo
  echo 'The above files have style errors.'
  echo "Use 'shfmt -d $@' option to show diff."
  echo "Use 'shfmt -w $@' option to write (autocorrect)."
  exit 1
else
  echo '[PASS]'
fi
