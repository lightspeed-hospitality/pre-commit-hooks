#!/usr/bin/env bash
# Original: https://github.com/syntaqx/git-hooks
# Forked to auto-install shfmt and give better command suggestions
# Original: https://github.com/jumanjihouse/pre-commit-hooks#shfmt
# Forked to change runtime to /usr/bin/env on win10
set -eu

CMD="shfmt"

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

    VERSION="v3.12.0"

    URL="https://github.com/mvdan/sh/releases/download/${VERSION}/${CMD}_${VERSION}_${OS}_${ARCH}"
    mkdir /tmp/hadolint
    pushd /tmp/hadolint

    echo "Fetching ${CMD} from ${URL}"
    # Getting a real file name (avoiding possible file name changes, if that happens, the sha256 check will fail)
    DOWNLOADED_FILE_NAME=$(curl -sSLJ --fail-with-body -O -w '%{filename_effective}' "$URL")
    chmod 755 "${DOWNLOADED_FILE_NAME}"

    SHA_FILE_NAME=$(curl -sSLJ --fail-with-body -O -w '%{filename_effective}' "$URL.sha256")
    sha256sum -c "${SHA_FILE_NAME}"

    cp "${DOWNLOADED_FILE_NAME}" "${HOME}/.local/bin/${CMD}"
    popd
  fi
fi

readonly cmd=(${CMD} "$@")
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
