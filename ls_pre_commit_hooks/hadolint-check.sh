#!/usr/bin/env bash
set -eo pipefail

CMD="hadolint"

if ! command -v ${CMD} &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install --quiet ${CMD}
  else

    case "$(uname -m)" in
          x86_64|amd64|x64) ARCH="x86_64" ;;
          aarch64|arm64) ARCH="arm64" ;;
          *) echo "Unknown machine type: $(uname -m)"; exit 1 ;;
    esac

    case "$(uname)" in
      Darwin) OS="macos" ;;
      Linux) OS="linux" ;;
      *) echo "Unknown OS: $(uname)"; exit 1 ;;
    esac

    VERSION="v2.13.1"

    URL="https://github.com/hadolint/hadolint/releases/download/${VERSION}/${CMD}-${OS}-${ARCH}"

    echo "Fetching ${CMD} from ${URL}"
    # Getting a real file name (avoiding possible file name changes, if that happens, the sha256 check will fail)
    DOWNLOADED_FILE_NAME=$(curl -sSLJ -O -w '%{filename_effective}' "$URL")
    chmod 755 "${DOWNLOADED_FILE_NAME}"

    SHA_FILE_NAME=$(curl -sSLJ -O -w '%{filename_effective}' "$URL.sha256")
    sha256sum -c "${SHA_FILE_NAME}"

    sudo mv "${DOWNLOADED_FILE_NAME}" "/usr/local/bin/${CMD}"
  fi
fi

${CMD} --version
exec "${CMD}" "$@"
