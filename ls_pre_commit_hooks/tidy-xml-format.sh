#!/usr/bin/env bash
CMD="tidy"
if ! command -v ${CMD} &>/dev/null; then

  if command -v brew &>/dev/null; then
    brew install --quiet ${CMD}
  else
    if ! command -v dpkg-deb &>/dev/null; then
      echo Neither dpkg-deb nor brew are on the system. Installation would need one or the other
      exit 1
    fi

    case "$(uname)" in
        Darwin) OS="macos" ;;
        Linux) OS="Linux" ;;
        *) echo "Unknown OS: $(uname)"; exit 1 ;;
    esac

    VERSION="v5.8.0"

    URL="https://github.com/htacg/tidy-html5/releases/download/${VERSION}/tidy-${VERSION}-${OS}-64bit.deb"
    mkdir "/tmp/${CMD}"
    pushd "/tmp/${CMD}"
    # Getting a real file name (avoiding possible file name changes, if that happens, the sha256 check will fail)
    DOWNLOADED_FILE_NAME=$(curl -sSLJ -O -w '%{filename_effective}' "$URL")
    dpkg-deb -x ${DOWNLOADED_FILE_NAME} .

    SHA_FILE_NAME=$(curl -sSLJ -O -w '%{filename_effective}' "$URL.sha256")
    sha256sum -c "${SHA_FILE_NAME}"

    sudo cp -a usr/. /usr/local/

    popd
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
  tidy -quiet -config $tidy_config -o "$xml_file" "$xml_file"
done
