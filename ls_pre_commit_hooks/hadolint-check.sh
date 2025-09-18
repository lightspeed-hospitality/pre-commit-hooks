#!/usr/bin/env bash

set -eo pipefail

if [[ "${OSTYPE}" == *"darwin"* ]] ; then
  OS="Darwin"
else
  OS="Linux"
  MACHINE_TYPE="$(uname -m)"
  case "$MACHINE_TYPE" in
      amd64 | x86_64 | x64)
          ARCH="x86_64"
          ;;
      aarch64 | arm64)
          ARCH="arm64"
          ;;
      *)
          echo "Unknown machine type: $MACHINE_TYPE"
          exit 1
          ;;
  esac
fi

if [[ $OS == "Darwin" ]]; then
  if ! command -v hadolint &>/dev/null; then
    if command -v brew &>/dev/null; then
      brew install --quiet hadolint
    else
      >&2 echo 'hadolint and brew not found. Please install brew and rerun the hook'
      exit 1
    fi
  fi
  CMD="hadolint"
else
  HADOLINT_VERSION="v2.13.1"
  URL="https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${OS}-${ARCH}"
  # Getting a real file name (avoiding possible file name changes, if that happens, the sha256 check will fail)
  FILE_NAME=$(curl -sIL $URL | grep -i content-disposition | grep filename= | sed 's/.*filename=\(.*\)/\1/')

  mkdir -p ".cache/hadolint-${HADOLINT_VERSION}"
  pushd ".cache/hadolint-${HADOLINT_VERSION}" > /dev/null

  if [ ! -f "${FILE_NAME}" ] ; then
    echo "Fetching hadolint from ${URL}"
    curl -sSL -O "$URL"
    chmod 755 "${FILE_NAME}"
  fi

  if [ ! -f "${FILE_NAME}.sha256" ] ; then
    curl -sSL -O "$URL.sha256"
  fi

  sha256sum -c "${FILE_NAME}.sha256"

  CMD=".cache/hadolint-${HADOLINT_VERSION}/${FILE_NAME}"
  popd > /dev/null
fi

$CMD --version
exec "$CMD" "$@"
