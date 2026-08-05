#!/usr/bin/env bash

_CIRCLECI_CASK="circleci-public/circleci/circleci@next"
_CIRCLECI_CASK_TOKEN="circleci@next"
_CIRCLECI_LEGACY_FORMULA="circleci"

function is_circleci_v1 {
  command -v circleci &>/dev/null && circleci version 2>/dev/null | grep -q '^circleci 1\.'
}

function refresh_circleci_path {
  hash -r 2>/dev/null || true
}

function ensure_circleci_v1 {
  if is_circleci_v1; then
    return 0
  fi

  if ! command -v brew &>/dev/null; then
    >&2 echo "Homebrew is required to install the supported CircleCI CLI: ${_CIRCLECI_CASK}."
    >&2 echo "See https://cli.circleci.com/ for other install options."
    exit 1
  fi

  echo "Installing supported CircleCI CLI (${_CIRCLECI_CASK})..."

  # The supported CLI is a cask. Unlink the legacy formula first so the cask's
  # install hooks can create the /opt/homebrew/bin/circleci link.
  if brew list --formula --versions "${_CIRCLECI_LEGACY_FORMULA}" &>/dev/null; then
    brew unlink "${_CIRCLECI_LEGACY_FORMULA}"
  fi

  if brew list --cask --versions "${_CIRCLECI_CASK_TOKEN}" &>/dev/null; then
    brew reinstall --cask "${_CIRCLECI_CASK}"
  else
    brew install --cask "${_CIRCLECI_CASK}"
  fi
  refresh_circleci_path

  if ! is_circleci_v1; then
    >&2 echo "Installed ${_CIRCLECI_CASK}, but PATH still resolves to a non-1.x circleci ($(command -v circleci 2>/dev/null || echo 'not found'))."
    >&2 echo "Ensure the cask's binary is available on PATH, or uninstall the conflicting circleci installation."
    exit 1
  fi
}
