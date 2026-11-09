#!/usr/bin/env bash

function is_circleci_v1 {
  command -v circleci >/dev/null 2>&1 &&
    circleci version 2>/dev/null | grep -Eq '^circleci 1(\.|[[:space:]])'
}

function install_circleci_cli {
  if ! command -v brew >/dev/null 2>&1; then
    >&2 echo "Homebrew is required to install CircleCI CLI. See https://cli.circleci.com/ for other install options."
    return 1
  fi

  echo "Installing CircleCI CLI with Homebrew (brew install circleci)..."
  if ! brew install circleci; then
    >&2 echo "Failed to install CircleCI CLI with Homebrew."
    return 1
  fi

  local brew_prefix
  if brew_prefix="$(brew --prefix 2>/dev/null)" && [[ -x "${brew_prefix}/bin/circleci" ]]; then
    PATH="${brew_prefix}/bin:${PATH}"
    export PATH
    hash -r 2>/dev/null || true
  fi

  if ! command -v circleci >/dev/null 2>&1; then
    >&2 echo "Homebrew installed CircleCI CLI, but circleci is not available on PATH."
    return 1
  fi
}

function ensure_circleci_cli {
  if command -v circleci >/dev/null 2>&1; then
    local current_version
    current_version="$(circleci version 2>/dev/null || true)"
    >&2 echo "Warning: using existing CircleCI CLI (${current_version:-unknown}); it will not be replaced."
    return 0
  fi

  install_circleci_cli
}
