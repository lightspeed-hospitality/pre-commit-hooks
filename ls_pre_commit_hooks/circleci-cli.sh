#!/usr/bin/env bash

_CIRCLECI_CASK="circleci-public/circleci/circleci@next"
_CIRCLECI_CASK_TOKEN="circleci@next"
_CIRCLECI_LEGACY_FORMULA="circleci"

function is_circleci_v1 {
  command -v circleci &>/dev/null && circleci version 2>/dev/null | grep -q '^circleci 1\.'
}

function prefer_homebrew_circleci {
  local brew_prefix
  if brew_prefix="$(brew --prefix 2>/dev/null)" && [[ -x "${brew_prefix}/bin/circleci" ]]; then
    PATH="${brew_prefix}/bin:${PATH}"
    export PATH
  fi
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
  if [[ "${OSTYPE:-}" != darwin* ]]; then
    >&2 echo "The supported CircleCI CLI cask requires macOS. Install CircleCI CLI 1.x manually on this platform."
    exit 1
  fi

  echo "Installing supported CircleCI CLI (${_CIRCLECI_CASK})..."

  # The supported CLI is a cask. Unlink the legacy formula first so the cask's
  # install hooks can create the Homebrew-prefix circleci link.
  legacy_formula_unlinked=0
  if brew list --formula --versions "${_CIRCLECI_LEGACY_FORMULA}" &>/dev/null; then
    if brew unlink "${_CIRCLECI_LEGACY_FORMULA}"; then
      legacy_formula_unlinked=1
    else
      >&2 echo "Could not unlink the conflicting ${_CIRCLECI_LEGACY_FORMULA} formula."
      exit 1
    fi
  fi

  if brew list --cask --versions "${_CIRCLECI_CASK_TOKEN}" &>/dev/null; then
    cask_install_command=(brew reinstall --cask "${_CIRCLECI_CASK}")
  else
    cask_install_command=(brew install --cask "${_CIRCLECI_CASK}")
  fi

  if ! "${cask_install_command[@]}"; then
    if [[ "${legacy_formula_unlinked}" -eq 1 ]]; then
      brew link "${_CIRCLECI_LEGACY_FORMULA}" || true
    fi
    >&2 echo "Failed to install ${_CIRCLECI_CASK}."
    exit 1
  fi
  prefer_homebrew_circleci

  if ! is_circleci_v1; then
    >&2 echo "Installed ${_CIRCLECI_CASK}, but PATH still resolves to a non-1.x circleci ($(command -v circleci 2>/dev/null || echo 'not found'))."
    >&2 echo "Ensure the cask's binary is available on PATH, or uninstall the conflicting circleci installation."
    exit 1
  fi
}
