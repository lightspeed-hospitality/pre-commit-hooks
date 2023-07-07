#!/usr/bin/env bash

set -x
set -e
set -o pipefail

HADOLINT_VERSION=v2.12.0

mkdir -p ".cache/hadolint-${HADOLINT_VERSION}"
pushd ".cache/hadolint-${HADOLINT_VERSION}" > /dev/null

if echo "${OSTYPE}" | grep -q darwin ; then
  OS="Darwin"
  ARCH="x86_64"  # There's no arm64 build as of 2023-07-07
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

URL="https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${OS}-${ARCH}"

FILE_NAME="hadolint-${OS}-${ARCH}"
if [ ! -f "${FILE_NAME}" ] ; then
  curl -sSL -o "${FILE_NAME}" "$URL"
  chmod 755 "${FILE_NAME}"
fi
if [ ! -f "${FILE_NAME}.sha256" ] ; then
  curl -sSL -o "${FILE_NAME}.sha256" "$URL.sha256"
fi

sha256sum -c "${FILE_NAME}.sha256"

popd > /dev/null
echo "Using hadolint version ${HADOLINT_VERSION}"

exec ".cache/hadolint-${HADOLINT_VERSION}/${FILE_NAME}" "$@"
