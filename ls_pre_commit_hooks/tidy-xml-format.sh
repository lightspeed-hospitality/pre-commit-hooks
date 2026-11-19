#!/usr/bin/env bash

TIDY_VERSION="5.8.0"
TIDY_DEB_URL="https://github.com/htacg/tidy-html5/releases/download/${TIDY_VERSION}/tidy-${TIDY_VERSION}-Linux-64bit.deb"
TIDY_DEB_SHA256="59e594312207234f5a17455683c13c6bc47a89cb7bf994d493acfffb591d9830"
# Lives next to pre-commit's own cache, which CI caches between builds.
TIDY_CACHE_DIR="${PRE_COMMIT_HOME:-${XDG_CACHE_HOME:-${HOME}/.cache}/pre-commit}/tidy-${TIDY_VERSION}"

# Extracts the release package instead of installing it, so it needs no sudo and no apt-get update.
install_tidy_release() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  echo "...downloading ${TIDY_DEB_URL}"
  if ! curl --silent --show-error --fail --location \
    --connect-timeout 10 --max-time 60 --retry 3 --retry-delay 1 \
    --output "${tmp_dir}/tidy.deb" "${TIDY_DEB_URL}"; then
    rm -rf "${tmp_dir}"
    return 1
  fi
  if ! echo "${TIDY_DEB_SHA256}  ${tmp_dir}/tidy.deb" | sha256sum --check --status; then
    >&2 echo "SHA-256 checksum validation failed for ${TIDY_DEB_URL}"
    rm -rf "${tmp_dir}"
    return 1
  fi
  dpkg-deb -x "${tmp_dir}/tidy.deb" "${tmp_dir}/extracted" &&
    mkdir -p "$(dirname "${TIDY_CACHE_DIR}")" &&
    rm -rf "${TIDY_CACHE_DIR}" &&
    mv "${tmp_dir}/extracted" "${TIDY_CACHE_DIR}"
  local result=$?
  rm -rf "${tmp_dir}"
  return ${result}
}

if command -v tidy &>/dev/null; then
  TIDY_CMD="tidy"
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" =~ ^(x86_64|amd64)$ ]] && command -v dpkg-deb &>/dev/null; then
  TIDY_CMD="${TIDY_CACHE_DIR}/usr/bin/tidy"
  if [[ ! -x "${TIDY_CMD}" ]]; then
    echo "tidy not found, installing tidy ${TIDY_VERSION}..."
    install_tidy_release || exit 1
  fi
else
  TIDY_CMD="tidy"
  echo "tidy not found, installing it..."
  if command -v brew &>/dev/null; then
    echo "...using brew"
    brew install tidy-html5
  elif command -v apt-get &>/dev/null; then
    # Fallback for platforms without an htacg release package, such as arm64.
    echo "...using apt-get"
    apt_options=(-o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30)
    sudo timeout 300 apt-get -qq "${apt_options[@]}" update &&
      sudo timeout 300 apt-get -qqy "${apt_options[@]}" install tidy || exit 1
  else
    >&2 echo 'tidy command not found. Get tidy from https://www.html-tidy.org/.'
    exit 1
  fi
fi

tidy_config=$(mktemp)
cat <<EOF > $tidy_config
indent: auto
indent-spaces: 4
output-xml: yes
input-xml: yes
wrap: 0
wrap-attributes: yes
indent-attributes: yes
vertical-space: yes
EOF

for xml_file in "${@}"; do
  "${TIDY_CMD}" -quiet -config $tidy_config -o "$xml_file" "$xml_file"
done
