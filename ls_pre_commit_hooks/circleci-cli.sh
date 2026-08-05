#!/usr/bin/env bash

_CIRCLECI_FORMULA="circleci-public/circleci/circleci@next"

function is_circleci_v1 {
  command -v circleci &>/dev/null && circleci version 2>/dev/null | grep -q '^circleci 1\.'
}

function prefer_homebrew_circleci {
  local brew_prefix
  if brew_prefix="$(brew --prefix "${_CIRCLECI_FORMULA}" 2>/dev/null)" \
    && [[ -x "${brew_prefix}/bin/circleci" ]]; then
    PATH="${brew_prefix}/bin:${PATH}"
    export PATH
    hash -r 2>/dev/null || true
  fi
}

function ensure_circleci_v1 {
  if is_circleci_v1; then
    return 0
  fi

  if ! command -v brew &>/dev/null; then
    >&2 echo "Homebrew is required to install the supported CircleCI CLI: ${_CIRCLECI_FORMULA}."
    >&2 echo "See https://cli.circleci.com/ for other install options."
    exit 1
  fi

  echo "Installing supported CircleCI CLI (${_CIRCLECI_FORMULA})..."
  if ! install_output="$(brew install "${_CIRCLECI_FORMULA}" 2>&1)"; then
    printf '%s\n' "${install_output}" >&2
    if [[ "${install_output}" == *"brew link --overwrite"* ]] \
      && brew list --formula --versions "${_CIRCLECI_FORMULA}" &>/dev/null; then
      echo "Retrying CircleCI CLI link with overwrite..."
      brew link --overwrite "${_CIRCLECI_FORMULA}"
    else
      exit 1
    fi
  fi
  prefer_homebrew_circleci

  if ! is_circleci_v1; then
    >&2 echo "Installed ${_CIRCLECI_FORMULA}, but PATH still resolves to a non-1.x circleci ($(command -v circleci 2>/dev/null || echo 'not found'))."
    >&2 echo "Put the Homebrew binary earlier on PATH, or uninstall the conflicting circleci."
    exit 1
  fi
}
